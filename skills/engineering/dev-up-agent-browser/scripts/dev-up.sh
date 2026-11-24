#!/usr/bin/env bash
# dev-up.sh: the mechanical half of the dev-up and dev-up-agent-browser skills. One dev server per
# port, one log, one state file; under dev-up-agent-browser, also one agent-browser session per
# port. Both skills ship this same file, byte for byte. It reads which skill it serves from the
# folder above scripts/ (symlinks resolved), so each skill keeps its own cache and state keys, and
# both run side by side.
#
# Usage: dev-up.sh <command> [PORT] [args]
#   owner PORT            FREE | BUSY pid=N cwd=DIR mine=yes|worktree|orphan|no|? via=dev-up|other
#                         state=mine|other|none. orphan: the listener's cwd was deleted. Exits 0 on
#                         FREE and on mine=yes, 1 otherwise.
#   preflight [DIR]       what this checkout needs before launch: run/todo/warn lines. warn served:
#                         a listener already runs from DIR
#   serve PORT [--dir DIR] [--mem SIZE] [--swap SIZE] -- CMD
#                         start CMD (one shell string) as the systemd user unit dev-up-PORT, logging
#                         to PORT.log, and return: STARTED unit=dev-up-PORT log=FILE. The unit gets
#                         MemoryMax (default 4G, or DEV_UP_MEM) and MemorySwapMax (default 1G, or
#                         DEV_UP_SWAP); --mem none lifts both. A server that exits with a failure
#                         (an error exit, oom-kill) starts again after 1 s, at most 5 starts in
#                         10 minutes; each fall logs "dev-up: server exited result=R code=C status=S".
#                         A stop logs nothing
#   wait PORT             READY http=N | HTTP_5XX http=N | DIED | BUSY_OTHER pid=N | BOUND_NO_HTTP | TIMEOUT
#   logs PORT [N]         the last N lines of PORT.log (default 40)
#   watch PORT            the Monitor command: new error lines from the log, minus noise and excludes,
#                         and every "dev-up: server exited" line
#   stop PORT [--force]   stop the unit serve started (systemd sends SIGKILL after 10 s), or an
#                         orphan listener: STOPPED | STILL_BOUND. --force: any listener
#   state PORT init | show | get KEY | set KEY=VALUE... | pause | resume | exclude 'TEXT' | rm
#   unwatched             for the UserPromptSubmit hook: this session's dead servers, and the errors
#                         logged since the last prompt when the watcher is gone
# Only under dev-up-agent-browser (dev-up answers "unknown command"):
#   ab PORT ARGS...       run agent-browser ARGS in the port's session (devup-PORT) with the same
#                         launch options on every call, so the daemon never relaunches the browser.
#                         A headless session shuts down after 30 min idle (DEV_UP_AB_IDLE changes it);
#                         a visible window never does.
#                         ab PORT js CODE runs agent-browser eval CODE; js - reads it from stdin.
#                         ab PORT screenshot ... DIR/FILE.png creates DIR when the last argument is
#                         an image path (any case), not a selector like text=a/b.png. Exits 3 when agent-browser
#                         itself does not run
#   show PORT | hide PORT switch the session to a visible window (headed) or back to headless,
#                         carrying cookies and storage: SWITCHED mode=M url=U | ALREADY mode=M |
#                         FAILED mode=M url=U, then agent-browser's reason and whether the server is down
#   login PORT [USER]     run this repo's login recipe from the checkout root: LOGGED_IN user=U url=U |
#                         LOGIN_FAILED exit=N | NO_RECIPE key=K file=F (exit 1)
#   recipe [set 'CMD' [USER] | rm]
#                         show, save or delete this repo's login recipe: RECIPE | SAVED | REMOVED |
#                         NO_RECIPE key=K file=F. CMD is a project command that logs in without
#                         printing the password; {port} and {user} stand for the port and the user
#   dash                  start the agent-browser dashboard once: DASH url=http://localhost:4848
#   browser PORT          the mode and executable the port's session uses
#
# Browsers: see headless_exe and headed_exe below. Every window gets --class=agent-browser, so a
# window manager rule can keep it from taking focus. Profiles and saved logins live in
# ~/.local/state/dev-up-ab.
#
# Login recipes live in ~/.config/dev-up-ab/logins (DEV_UP_AB_CONFIG, else XDG_CONFIG_HOME), one
# file per repo, named after its origin URL (host/owner/repo), else its git common dir, so every
# worktree and clone of a repo finds the same one. Lines: cmd=CMD and an optional user=DEFAULT.
#
# Files in ~/.cache/dev-up (dev-up) or ~/.cache/dev-up-ab (dev-up-agent-browser): PORT.log,
# PORT.state (session dir watcher_task, plus tab_id or ab_mode), PORT.watch (watch), PORT.paused,
# PORT.exclude (fixed strings, one per line), PORT.hookoff (log offset at the last prompt).
# Exit codes: 0 ok, 1 negative verdict, 2 usage, 3 refused.
set -uo pipefail

SELF=$(readlink -f "$0" 2>/dev/null)
SKILL=$(basename "$(dirname "$(dirname "${SELF:-$0}")")")
if [ "$SKILL" = dev-up-agent-browser ]; then
  CACHE="${DEV_UP_CACHE:-$HOME/.cache/dev-up-ab}" KEYS="session dir watcher_task ab_mode"
else
  SKILL=dev-up CACHE="${DEV_UP_CACHE:-$HOME/.cache/dev-up}" KEYS="session dir watcher_task tab_id"
fi
STATE_DIR="${DEV_UP_AB_STATE:-${XDG_STATE_HOME:-$HOME/.local/state}/dev-up-ab}"
CONFIG_DIR="${DEV_UP_AB_CONFIG:-${XDG_CONFIG_HOME:-$HOME/.config}/dev-up-ab}"
ERRORS='[Ee]rror|Exception|Traceback|Failed to compile|unhandled|ECONNREFUSED|EADDRINUSE|panic|FATAL|^dev-up: server exited'
NOISE='NEXT_REDIRECT|PoolError|QueuePool limit|Too many connections|favicon\.ico|SIGTERM|terminated by signal|exit code 143|(GET|POST|PUT|PATCH|DELETE|HEAD|OPTIONS) [^ ]+( HTTP/[0-9.]+"?)? [23][0-9][0-9]([^0-9]|$)'

say() { printf '%s\n' "$*"; }
usage() { awk 'NR > 1 && !/^#/ { exit } NR > 1' "$0"; }
die() { local code="$1"; shift; say "ERROR: $*" >&2; exit "$code"; }
have() { command -v "$1" >/dev/null 2>&1; }
need_port() { case "${1:-}" in ''|*[!0-9]*) die 2 "PORT must be a number, got '${1:-}'";; esac; }
need_tool() { have ss || have lsof || die 3 "neither ss nor lsof exists; cannot see who holds a port"; }
f() { say "$CACHE/$1.$2"; }
alive() { [ -n "${1:-}" ] && kill -0 "$1" 2>/dev/null; }
session_id() { say "${CLAUDE_CODE_SESSION_ID:-}"; }

bound() {
  if have ss; then [ -n "$(ss -ltnH "sport = :$1" 2>/dev/null)" ]
  else lsof -nP -iTCP:"$1" -sTCP:LISTEN >/dev/null 2>&1; fi
}

listeners() {
  if have ss; then ss -ltnpH 2>/dev/null | awk '{ n = split($4, a, ":"); if (match($0, /pid=[0-9]+/)) print a[n], substr($0, RSTART + 4, RLENGTH - 4) }'
  else lsof -nP -iTCP -sTCP:LISTEN -Fpn 2>/dev/null | awk '/^p/ { pid = substr($0, 2) } /^n/ { n = split($0, a, ":"); print a[n], pid }'; fi | sort -un
}

listener_pid() {
  if have ss; then ss -ltnpH "sport = :$1" 2>/dev/null | grep -oE 'pid=[0-9]+' | head -1 | cut -d= -f2
  else lsof -tnP -iTCP:"$1" -sTCP:LISTEN 2>/dev/null | head -1; fi
}

unit() { say "dev-up-$1"; }
# Alive includes the second between a fall and its restart (activating/auto-restart).
served() {
  case "$(systemctl --user show -p ActiveState --value "$(unit "$1")" 2>/dev/null)" in
    active|activating|deactivating|reloading|refreshing) return 0 ;;
  esac
  return 1
}
restarting() {
  case "$(systemctl --user show -p ActiveState -p SubState --value "$(unit "$1")" 2>/dev/null | tr '\n' /)" in
    */auto-restart*|deactivating/*) return 0 ;;
  esac
  return 1
}
last_fall() { grep '^dev-up: server exited' "$(f "$1" log)" 2>/dev/null | tail -1; }
in_unit() { [ -n "${1:-}" ] && grep -qE "/$(unit "$2")\.service\$" "/proc/$1/cgroup" 2>/dev/null; }
orphan() { case "$1" in *' (deleted)') [ ! -d "$1" ]; return ;; esac; return 1; }

tree() {
  ps -eo pid=,ppid= | awk -v root="$1" '
    { kids[$2] = kids[$2] " " $1 }
    END { q = root; out = root
          while (q != "") { n = split(q, a, " "); q = ""
            for (i = 1; i <= n; i++) { m = split(kids[a[i]], k, " ")
              for (j = 1; j <= m; j++) { out = out " " k[j]; q = q " " k[j] } } }
          print out }'
}

toplevel() { git -C "$1" rev-parse --show-toplevel 2>/dev/null || (cd "$1" && pwd -P); }
common_dir() { git -C "$1" rev-parse --path-format=absolute --git-common-dir 2>/dev/null; }
proc_cwd() { readlink "/proc/$1/cwd" 2>/dev/null || lsof -a -p "$1" -d cwd -Fn 2>/dev/null | sed -n 's/^n//p'; }

state_get() { sed -n "s/^$2=//p" "$(f "$1" state)" 2>/dev/null | tail -1; }
state_owner() {
  local s; s=$(state_get "$1" session)
  if [ ! -f "$(f "$1" state)" ]; then say none
  elif [ -n "$s" ] && [ "$s" = "$(session_id)" ]; then say mine
  else say other; fi
}
via() { if in_unit "$1" "$2"; then say dev-up; else say other; fi; }

cmd_owner() {
  local port="$1" pid cwd here mine=no
  need_tool
  bound "$port" || { say FREE; return 0; }
  pid=$(listener_pid "$port")
  [ -n "$pid" ] || { say "BUSY pid=? cwd=? mine=? via=other state=$(state_owner "$port")"; return 1; }
  cwd=$(proc_cwd "$pid")
  here=$(toplevel "$PWD")
  if orphan "$cwd"; then mine=orphan
  elif [ -n "$cwd" ] && [ "$(toplevel "$cwd")" = "$here" ]; then mine=yes
  elif [ -n "$cwd" ] && [ -n "$(common_dir "$PWD")" ] && [ "$(common_dir "$cwd")" = "$(common_dir "$PWD")" ]; then mine=worktree
  fi
  say "BUSY pid=$pid cwd=${cwd:-?} mine=$mine via=$(via "$pid" "$port") state=$(state_owner "$port")"
  [ "$mine" = yes ]
}

q() { printf '%q' "$1"; }

cmd_preflight() {
  local dir top main wt=no lock="" mgr="" install=""
  dir=$(cd "${1:-$PWD}" && pwd -P) || die 2 "no such dir ${1:-}"
  top=$(toplevel "$dir")
  main=$(git -C "$dir" worktree list --porcelain 2>/dev/null | sed -n '1s/^worktree //p')
  [ -n "$main" ] && [ "$main" != "$top" ] && wt=yes
  say "ok checkout $top worktree=$wt"
  local lport lpid
  while read -r lport lpid; do
    [ "$(proc_cwd "$lpid")" = "$dir" ] && say "warn served: this directory already serves port $lport (pid $lpid)"
  done < <(listeners)

  local d l
  for d in "$dir" "$top"; do
    for l in bun.lock bun.lockb pnpm-lock.yaml yarn.lock package-lock.json; do
      [ -z "$lock" ] && [ -f "$d/$l" ] && lock="$d/$l"
    done
  done
  case "$lock" in
    */bun.lock|*/bun.lockb) mgr=bun; install="bun install --frozen-lockfile" ;;
    */pnpm-lock.yaml) mgr=pnpm; install="pnpm install --frozen-lockfile" ;;
    */yarn.lock) mgr=yarn; install="yarn install --frozen-lockfile" ;;
    */package-lock.json) mgr=npm; install="npm ci" ;;
  esac
  if [ -f "$dir/package.json" ]; then
    grep -E '"dev"[[:space:]]*:' "$dir/package.json" | sed 's/^[[:space:]]*/ok dev script: /'
    if [ -z "$mgr" ]; then say "todo no lockfile found; install the dependencies the way the README says"
    elif [ -d "$dir/node_modules" ]; then say "ok node_modules present, manager $mgr"
    else say "run cd $(q "$(dirname "$lock")") && $install"
    fi
  fi

  if [ -f "$dir/pyproject.toml" ] || [ -f "$dir/requirements.txt" ]; then
    if [ -d "$dir/.venv" ]; then say "ok .venv present; serve puts .venv/bin first on PATH"
    elif [ -f "$dir/uv.lock" ]; then say "run cd $(q "$dir") && uv sync"
    elif [ -f "$dir/requirements.txt" ]; then say "run cd $(q "$dir") && python3 -m venv .venv && .venv/bin/pip install -r requirements.txt"
    else say "todo create $dir/.venv the way the README says"
    fi
  fi

  if [ "$wt" = yes ]; then
    local rel="${dir#"$top"}" e
    for e in .env .env.local .env.development .env.development.local; do
      { [ -e "$dir/$e" ] || [ ! -f "$main$rel/$e" ]; } && continue
      if git -C "$dir" check-ignore -q "$e"; then say "run ln -s $(q "$main$rel/$e") $(q "$dir/$e")"
      else say "todo $e exists in the main checkout but is not gitignored here; ask before copying it"; fi
    done
  fi

  local file key port
  for file in "$dir"/.env "$dir"/.env.local "$dir"/.env.development "$dir"/.env.development.local; do
    [ -f "$file" ] || continue
    sed -nE 's#^(export[[:space:]]+)?([A-Za-z_][A-Za-z0-9_]*)=["'"'"']?https?://(localhost|127\.0\.0\.1):([0-9]+).*#\2 \4#p' "$file" |
      while read -r key port; do
        case "$key" in *SUPABASE*|*API*|*DATABASE*|*DB_*|*REDIS*|*POSTGRES*|*MONGO*) continue ;; esac
        case "$key" in *AUTH*|*SITE*|*APP_URL*|*BASE_URL*|*PUBLIC_URL*|*FRONTEND*|*WEB_URL*|*ORIGIN*|*CALLBACK*|*REDIRECT*) ;; *) continue ;; esac
        say "warn pinned port: $(basename "$file") $key expects port $port"
      done
  done
  return 0
}

cmd_serve() {
  local port="$1" dir="$PWD" mem="${DEV_UP_MEM:-4G}" swap="${DEV_UP_SWAP:-1G}"; shift
  while [ $# -gt 0 ]; do
    case "$1" in
      --dir) dir="${2:-}"; shift 2 ;;
      --mem) mem="${2:-}"; shift 2 ;;
      --swap) swap="${2:-}"; shift 2 ;;
      --) shift; break ;;
      *) die 2 "serve: unknown argument '$1' (the command goes after --)" ;;
    esac
  done
  [ $# -gt 0 ] || die 2 "serve: missing the command after --"
  have systemd-run || die 3 "serve needs a systemd user manager (systemd-run --user)"
  mkdir -p "$CACHE"
  local log; log=$(f "$port" log)
  if bound "$port"; then say "dev-up serve: port $port is already bound; nothing started" >>"$log"; die 3 "port $port is already bound"; fi
  served "$port" && die 3 "unit $(unit "$port") is already running; stop $port first"
  cd "$dir" 2>/dev/null || { say "dev-up serve: no such dir $dir" >>"$log"; die 2 "serve: no such dir $dir"; }
  [ -f "$log" ] && mv "$log" "$log.1"
  rm -f "$(f "$port" hookoff)"
  local top v c; top=$(toplevel "$PWD")
  PATH="$PWD/node_modules/.bin:$top/node_modules/.bin:$PATH"
  [ -d .venv/bin ] && PATH="$PWD/.venv/bin:$PATH"
  # A service unit starts from the user manager's environment, not this shell's: copy every
  # exported variable by name. Values stay off the command line; systemd keeps them in the
  # unit's transient file under /run/user, readable only by this user.
  # next dev exits 1 to show an upgrade notice when it sees an agent in the environment (CLAUDECODE,
  # AI_AGENT, which this unit inherits) and starts on the retry; an oom-kill
  # used to leave the port dead. Both come back; a server that falls 5 times in 10 minutes, fast
  # or slow, stays down. ExecStopPost logs why each run ended, except a clean exit and a stop
  # (cmd_stop leaves PORT.stopping while it runs).
  local -a env=() props=(-p TimeoutStopSec=10 -p Restart=on-failure -p RestartSec=1
    -p StartLimitIntervalSec=600 -p StartLimitBurst=5
    -p "ExecStopPost=$(command -v bash) -c '[ \"\$\$SERVICE_RESULT\" = success ] || [ -e \"\$\$DEV_UP_STOPPING\" ] || echo \"dev-up: server exited result=\$\$SERVICE_RESULT code=\$\$EXIT_CODE status=\$\$EXIT_STATUS\" >>\"\$\$DEV_UP_LOG\"'")
  for v in $(compgen -e); do env+=(--setenv="$v"); done
  env+=(--setenv="DEV_UP_LOG=$log" --setenv="DEV_UP_STOPPING=$(f "$port" stopping)")
  rm -f "$(f "$port" stopping)"
  # Capped by default: an uncapped dev server grew past 5 GiB of RAM and kept 2 to 3 GiB in swap
  # (measured on two servers, 11 Nov 2026), and four of them left the machine without memory. With
  # MemoryMax alone the server spills into swap without limit, so the swap gets its own ceiling.
  [ -n "$mem" ] && [ "$mem" != none ] && props+=(-p "MemoryMax=$mem" -p "MemorySwapMax=$swap")
  # systemd expands ${VAR} and $$ in ExecStart before bash runs; $$ is its escape for a literal $.
  c="exec >>$(q "$log") 2>&1; $*"
  systemctl --user reset-failed "$(unit "$port")" 2>/dev/null
  systemd-run --user --quiet --collect --unit="$(unit "$port")" --working-directory="$PWD" \
    "${env[@]}" "${props[@]}" -- bash -c "${c//\$/\$\$}" \
    || die 3 "systemd-run could not start $(unit "$port")"
  say "STARTED unit=$(unit "$port") log=$log"
}

cmd_wait() {
  local port="$1" log lp code end i=0
  log=$(f "$port" log)
  end=$(($(date +%s) + 240))
  while :; do
    if ! served "$port"; then
      i=$((i + 1))
      if [ $i -ge 10 ]; then say DIED; tail -20 "$log" 2>/dev/null; return 1; fi
    elif bound "$port"; then
      lp=$(listener_pid "$port")
      if [ -n "$lp" ] && ! in_unit "$lp" "$port"; then say "BUSY_OTHER pid=$lp"; return 1; fi
      break
    fi
    [ "$(date +%s)" -lt "$end" ] || { say TIMEOUT; tail -20 "$log" 2>/dev/null; return 1; }
    sleep 0.5
  done
  code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 60 --retry 30 --retry-connrefused --retry-delay 1 --retry-max-time 240 "http://localhost:$port/")
  case "$code" in
    ''|000) say BOUND_NO_HTTP; tail -20 "$log"; return 1 ;;
    5*) say "HTTP_5XX http=$code"; tail -20 "$log"; return 1 ;;
    *) say "READY http=$code" ;;
  esac
}

cmd_watch() {
  local port="$1" exc
  mkdir -p "$CACHE"
  say $$ >"$(f "$port" watch)"
  rm -f "$(f "$port" paused)"
  exc=$(f "$port" exclude); [ -f "$exc" ] || : >"$exc"
  : >>"$(f "$port" log)"
  if ! in_unit "$(listener_pid "$port")" "$port"; then
    say "dev-up: port $port was not started by serve; this watcher reports only the server going down"
  fi
  trap 'pkill -P $$ 2>/dev/null; exit 0' TERM INT HUP
  # One report per fall: after a restart binds the port again, the probe watches for the next one.
  # It polls, so a fall within about 1 s of the restart reads as the same fall.
  ( while :; do
      while bound "$port"; do sleep 5; done; say "dev-up: SERVER DOWN on port $port"
      until bound "$port"; do sleep 1; done
    done ) &
  tail -n 0 -F "$(f "$port" log)" 2>/dev/null \
    | grep -E --line-buffered "$ERRORS" \
    | grep -vE --line-buffered "$NOISE" \
    | grep -vF --line-buffered -f "$exc" &
  wait
}

cmd_stop() {
  local port="$1" force="${2:-}" lp cwd="" p i
  need_tool
  bound "$port" || served "$port" || { say STOPPED; return 0; }
  lp=$(listener_pid "$port")
  [ -n "$lp" ] && cwd=$(proc_cwd "$lp")
  if served "$port" && { [ -z "$lp" ] || in_unit "$lp" "$port"; }; then
    : >"$(f "$port" stopping)"
    systemctl --user stop "$(unit "$port")" 2>/dev/null
    rm -f "$(f "$port" stopping)"
  elif orphan "$cwd" || [ "$force" = --force ]; then
    [ -n "$lp" ] || die 3 "cannot see the listener's pid (another user's process?)"
    for p in $(tree "$lp"); do kill -TERM "$p" 2>/dev/null; done
  else
    die 3 "port $port is held by pid ${lp:-?}, which serve did not start; ask the user, then use --force"
  fi
  for i in $(seq 20); do
    if ! bound "$port" && ! served "$port"; then
      if orphan "$cwd"; then say "STOPPED orphan pid=$lp cwd=$cwd"; else say STOPPED; fi
      return 0
    fi
    sleep 0.5
  done
  say "STILL_BOUND (something respawns it or ignores SIGTERM; tell the user)"; return 1
}

state_write() {
  local sf tmp drop="" kv; sf=$(f "$1" state); shift
  tmp=$(mktemp "$sf.XXXXXX") || die 3 "cannot write $sf"
  for kv in "$@"; do drop="$drop${drop:+|}${kv%%=*}"; done
  { [ -f "$sf" ] && grep -vE "^($drop)=" "$sf"; printf '%s\n' "$@"; } >"$tmp"
  mv "$tmp" "$sf"
}

check_kv() {
  local k="${1%%=*}" v="${1#*=}"
  [ "$k" != "$1" ] || die 2 "expected KEY=VALUE, got '$1'"
  case " $KEYS " in *" $k "*) ;; *) die 2 "unknown key '$k' (known: $KEYS)";; esac
  case "$k" in
    *_task) case "$v" in *[!A-Za-z0-9_-]*|PENDING|pending|pendente) die 3 "$k takes the real task id from the tool's return, got '$v'" ;; esac ;;
  esac
}

cmd_state() {
  local port="$1" op="${2:-show}" sf
  shift; [ $# -gt 0 ] && shift
  mkdir -p "$CACHE"; sf=$(f "$port" state)
  case "$op" in
    init)
      if [ "$(state_owner "$port")" = mine ]; then
        state_write "$port" "dir=$(toplevel "$PWD")"
        say "kept: this session already owns $sf"; cat "$sf"; return 0
      fi
      [ "$(state_get "$port" dir)" = "$(toplevel "$PWD")" ] || rm -f "$(f "$port" exclude)"
      rm -f "$sf" "$(f "$port" paused)"
      state_write "$port" "session=$(session_id)" "dir=$(toplevel "$PWD")"
      cat "$sf" ;;
    get) state_get "$port" "${1:?state PORT get KEY}" ;;
    set)
      [ $# -gt 0 ] || die 2 "state PORT set KEY=VALUE..."
      [ -f "$sf" ] || die 3 "no state for $port; run 'state $port init' first"
      local kv; for kv in "$@"; do check_kv "$kv"; done
      state_write "$port" "$@" ;;
    pause) : >"$(f "$port" paused)"; say "paused: the hook stays quiet until watch runs again" ;;
    resume) rm -f "$(f "$port" paused)"; say "resumed: the hook reports new errors again" ;;
    exclude)
      local text="${1:?state PORT exclude 'TEXT'}" exc; exc=$(f "$port" exclude)
      [ "${#text}" -ge 4 ] || die 2 "exclude takes a literal piece of the log line, at least 4 characters"
      grep -qxF -e "$text" "$exc" 2>/dev/null || say "$text" >>"$exc"
      say "excluded (fixed string): $text" ;;
    show)
      [ -f "$sf" ] || { say "no state for $port"; return 1; }
      cat "$sf"
      local wp; wp=$(cat "$(f "$port" watch)" 2>/dev/null)
      say "server_alive=$(served "$port" && echo yes || echo no) watcher_alive=$(alive "$wp" && echo yes || echo no) paused=$([ -f "$(f "$port" paused)" ] && echo yes || echo no)"
      [ "$SKILL" = dev-up-agent-browser ] && say "browser_alive=$(ab_alive "$port" && echo yes || echo no) mode=$(ab_mode "$port") session=$(ab_session "$port")"
      [ -s "$(f "$port" exclude)" ] && sed 's/^/excluded: /' "$(f "$port" exclude)"
      return 0 ;;
    rm) rm -f "$sf" "$(f "$port" watch)" "$(f "$port" paused)" "$(f "$port" exclude)" "$(f "$port" hookoff)" "$(f "$port" pid)" ;;
    *) die 2 "state: unknown op '$op'" ;;
  esac
}

cmd_unwatched() {
  local sid sf port wp log exc off size new
  sid=$(session_id)
  if [ -z "$sid" ] && [ ! -t 0 ]; then
    sid=$(sed -nE 's/.*"session_id"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/p' | head -1)
  fi
  [ -n "$sid" ] || return 0
  for sf in "$CACHE"/*.state; do
    [ -f "$sf" ] || continue
    port=$(basename "$sf" .state)
    [ "$(state_get "$port" session)" = "$sid" ] || continue
    wp=$(cat "$(f "$port" watch)" 2>/dev/null)
    if bound "$port" || restarting "$port"; then :
    elif served "$port"; then
      say "dev-up: the unit on port $port runs but nothing listens on the port (log: $(f "$port" log))."
    else
      say "dev-up: the server on port $port is down (log: $(f "$port" log)). Its state is cleared; run /dev-up $port to bring it back."
      last_fall "$port"
      rm -f "$sf" "$(f "$port" watch)" "$(f "$port" paused)" "$(f "$port" hookoff)" "$(f "$port" pid)"
      continue
    fi
    log=$(f "$port" log)
    size=0; [ -f "$log" ] && size=$(wc -c <"$log" | tr -d ' ')
    if ! alive "$wp" && [ ! -f "$(f "$port" paused)" ]; then
      off=$(cat "$(f "$port" hookoff)" 2>/dev/null); off=${off:-0}
      [ "$size" -lt "$off" ] && off=0
      exc=$(f "$port" exclude); [ -f "$exc" ] || : >"$exc"
      new=$(tail -c +"$((off + 1))" "$log" 2>/dev/null | grep -E "$ERRORS" | grep -vE "$NOISE" | grep -vF -f "$exc" | tail -5)
      [ -n "$new" ] && { say "dev-up: port $port logged errors since the last prompt:"; say "$new"; }
    fi
    say "$size" >"$(f "$port" hookoff)"
  done
  return 0
}

# agent-browser keeps one daemon per session and relaunches the browser when a call's launch options
# differ from the running ones (measured: a call without --args reopened Brave without its class;
# one without --executable-path fell back to the env's browser on about:blank). Every call goes
# through ab_env, so each one carries the same options.
ab_session() { say "devup-$1"; }
ab_mode() { local m; m=$(state_get "$1" ab_mode); say "${m:-headless}"; }
ab_alive() { agent-browser session list 2>/dev/null | grep -qw -- "$(ab_session "$1")"; }
# Headless: DEV_UP_AB_HEADLESS, else the newest Playwright chrome-headless-shell (about half the RAM
# of a full browser per session), else the env's AGENT_BROWSER_EXECUTABLE_PATH, else agent-browser's
# own Chrome. Headed: DEV_UP_AB_HEADED, else the env's browser, else agent-browser's Chrome.
headless_exe() {
  local base hs
  [ -n "${DEV_UP_AB_HEADLESS:-}" ] && { say "$DEV_UP_AB_HEADLESS"; return; }
  for base in "${PLAYWRIGHT_BROWSERS_PATH:-}" "$HOME/.cache/ms-playwright"; do
    [ -n "$base" ] || continue
    # shellcheck disable=SC2012 # Playwright names these folders; sort -V needs the list
    hs=$(ls -d "$base"/chromium_headless_shell-*/chrome-headless-shell-*/chrome-headless-shell 2>/dev/null | sort -V | tail -1)
    [ -n "$hs" ] && [ -x "$hs" ] && { say "$hs"; return; }
  done
  say "${AGENT_BROWSER_EXECUTABLE_PATH:-}"
}
headed_exe() { say "${DEV_UP_AB_HEADED:-${AGENT_BROWSER_EXECUTABLE_PATH:-}}"; }
ab_env() {
  local port="$1" mode; mode=$(ab_mode "$port")
  mkdir -p "$STATE_DIR/profiles" && chmod 700 "$STATE_DIR"
  export AGENT_BROWSER_SESSION; AGENT_BROWSER_SESSION=$(ab_session "$port")
  export AGENT_BROWSER_PROFILE="$STATE_DIR/profiles/$port-$mode"
  export AGENT_BROWSER_ARGS="--class=agent-browser"
  # The outdated-Chrome check fetches Google's release blog on every launch and prints a CVE
  # warning on every call; the session only ever opens localhost.
  export AGENT_BROWSER_NO_VERSION_CHECK=1
  local exe
  if [ "$mode" = headed ]; then export AGENT_BROWSER_HEADED=1; exe=$(headed_exe)
  else unset AGENT_BROWSER_HEADED; exe=$(headless_exe); fi
  # DEV_UP_AB_NOWINDOW=1 keeps the mode's browser and profile but shows no window.
  [ "${DEV_UP_AB_NOWINDOW:-}" = 1 ] && unset AGENT_BROWSER_HEADED
  if [ -n "$exe" ]; then export AGENT_BROWSER_EXECUTABLE_PATH="$exe"; else unset AGENT_BROWSER_EXECUTABLE_PATH; fi
}
# A headless session closes after DEV_UP_AB_IDLE (default 30m) idle. A visible window is the user's
# and stays: 0 turns the timeout off. The daemon applies a changed value in place, without a relaunch.
ab_idle() { if [ "$(ab_mode "$1")" = headed ]; then say 0; else say "${DEV_UP_AB_IDLE:-30m}"; fi; }
cmd_ab() {
  local port="$1" list a shot="" skip="" idle; shift
  have agent-browser || die 3 "agent-browser is not on PATH"
  [ $# -gt 0 ] || die 2 "ab PORT <agent-browser command...>"
  # A version manager's shim with no binary behind it passes have and fails every call.
  list=$(agent-browser session list 2>&1) || die 3 "agent-browser is on PATH but does not run: $(say "$list" | head -1)"
  if [ "$1" = js ]; then
    shift; if [ "${1:-}" = - ]; then shift; set -- eval --stdin "$@"; else set -- eval "$@"; fi
  fi
  # screenshot [selector] [path]: only the last positional argument can be the path.
  if [ "$1" = screenshot ]; then
    for a in "${@:2}"; do
      if [ -n "$skip" ]; then skip=""; continue; fi
      case "$a" in
        --threshold|--screenshot-dir|--screenshot-quality|--screenshot-format) skip=1 ;;
        -*) ;;
        *) shot="$a" ;;
      esac
    done
    case "${shot%%/*}" in *=*) shot="" ;; esac
    case "$(say "$shot" | tr '[:upper:]' '[:lower:]')" in
      */*.png|*/*.jpg|*/*.jpeg|*/*.webp) mkdir -p "$(dirname "$shot")" ;;
    esac
  fi
  idle=$(ab_idle "$port")
  # A dead daemon (idle timeout, a crash) would come back on about:blank for any command but open.
  case "$1" in
    open|goto|navigate|close|quit|exit|session|state|skills|dashboard|install|--*) ;;
    *) if ! say "$list" | grep -qw -- "$(ab_session "$port")"; then
         say "dev-up: the session on port $port had closed; reopened it at http://localhost:$port/" >&2
         ( ab_env "$port"; agent-browser --idle-timeout "$idle" open "http://localhost:$port/" >/dev/null 2>&1 )
       fi ;;
  esac
  ( ab_env "$port"; exec agent-browser --idle-timeout "$idle" "$@" )
}
cmd_switch() {
  local port="$1" want="$2" url="" auth out
  [ "$(ab_mode "$port")" = "$want" ] && ab_alive "$port" && { say "ALREADY mode=$want"; return 0; }
  auth="$STATE_DIR/auth-$port.json"
  if ab_alive "$port"; then
    url=$(cmd_ab "$port" get url 2>/dev/null | tail -1)
    cmd_ab "$port" state save "$auth" >/dev/null 2>&1 && chmod 600 "$auth"
    cmd_ab "$port" close >/dev/null 2>&1
  elif [ -d "$STATE_DIR/profiles/$port-$(ab_mode "$port")" ]; then
    # The session closed (idle timeout) after a login in its profile: read the profile back with
    # no window, or the other mode opens logged out.
    ( export DEV_UP_AB_NOWINDOW=1
      cmd_ab "$port" open "http://localhost:$port/" >/dev/null 2>&1 &&
        cmd_ab "$port" state save "$auth" >/dev/null 2>&1 && chmod 600 "$auth"
      cmd_ab "$port" close >/dev/null 2>&1 )
  fi
  case "$url" in http*) ;; *) url="http://localhost:$port/" ;; esac
  [ -f "$(f "$port" state)" ] || state_write "$port" "session=$(session_id)" "dir=$(toplevel "$PWD")"
  state_write "$port" "ab_mode=$want"
  # --state cannot go with --profile ("Cannot use storage_state with profile"): open, load, reopen.
  # A failed open can still have launched the window: on 17 Nov a show failed on a server that had
  # just been oom-killed. Name agent-browser's reason and a dead server, never just FAILED.
  if ! out=$(cmd_ab "$port" open "$url" 2>&1); then
    say "FAILED mode=$want url=$url"
    say "$out" | grep -v '^⚠' | tail -2
    bound "$port" || say "nothing listens on port $port: the server is down; bring it back, then show again"
    return 1
  fi
  if [ -s "$auth" ]; then
    cmd_ab "$port" state load "$auth" >/dev/null 2>&1 && cmd_ab "$port" open "$url" >/dev/null 2>&1
  fi
  say "SWITCHED mode=$want url=$url"
}
# The login recipe of the repo this checkout belongs to. Its key is the same in every worktree and
# clone: the origin URL as host/owner/repo, else the git common dir.
repo_key() {
  local top url; top=$(toplevel "$PWD")
  url=$(git -C "$top" config --get remote.origin.url 2>/dev/null)
  if [ -n "$url" ]; then
    url=${url%/}; url=${url%.git}; url=${url#*://}; url=${url#*@}
    case "$url" in *:*) case "${url%%:*}" in */*) ;; *) url="${url%%:*}/${url#*:}" ;; esac ;; esac
    say "$url" | tr '[:upper:]' '[:lower:]'
  else
    say "local$(common_dir "$top" || say "$top")"
  fi
}
recipe_file() { local k; k=$(repo_key); say "$CONFIG_DIR/logins/$(printf '%s' "$k" | tr -c 'A-Za-z0-9._-' '_')"; }
recipe_get() { sed -n "s/^$1=//p" "$(recipe_file)" 2>/dev/null | tail -1; }
no_recipe() { say "NO_RECIPE key=$(repo_key) file=$(recipe_file)"; return 1; }
cmd_recipe() {
  local op="${1:-show}" rf; rf=$(recipe_file)
  case "$op" in
    show) [ -s "$rf" ] || { no_recipe; return; }
      say "RECIPE key=$(repo_key) file=$rf"; grep -v '^#' "$rf" ;;
    set)
      local c="${2:-}" u="${3:-}"
      [ -n "$c" ] || die 2 "recipe set 'CMD' [USER]: CMD logs in on {port} without printing the password"
      case "$c" in *'{port}'*) ;; *) die 2 "the recipe must take the port as {port}" ;; esac
      case "$c$u" in *[[:cntrl:]]*) die 2 "the recipe is one line" ;; esac
      # A recipe names a command; the password stays in the project's own ignored file.
      say "$c" | grep -qiE 'pass(word)?=|senha=|--password[= ]' && die 3 "the recipe holds no password; point it at a command that reads the project's own file"
      mkdir -p "$CONFIG_DIR/logins" && chmod 700 "$CONFIG_DIR"
      { say "# dev-up-agent-browser login recipe for $(repo_key)"; say "cmd=$c"; [ -n "$u" ] && say "user=$u"; } >"$rf"
      chmod 600 "$rf"
      say "SAVED key=$(repo_key) file=$rf" ;;
    rm) rm -f "$rf"; say "REMOVED key=$(repo_key)" ;;
    *) die 2 "recipe: unknown op '$op' (show, set, rm)" ;;
  esac
}
cmd_login() {
  local port="$1" user="${2:-}" c out rc url qu
  c=$(recipe_get cmd)
  [ -n "$c" ] || { no_recipe; say "No recipe: ask the user to log in in the window, and offer to save one"; return 1; }
  [ -n "$user" ] || user=$(recipe_get user)
  case "$c" in *'{user}'*) [ -n "$user" ] || die 2 "login PORT USER: the recipe takes {user} and names no default" ;; esac
  # Quoted, so an & in the user stays a character (bash 5.2 expands it in a bare replacement).
  qu=$(q "$user"); c=${c//\{port\}/$port}; c=${c//\{user\}/"$qu"}
  ab_alive "$port" || cmd_ab "$port" open "http://localhost:$port/" >/dev/null 2>&1
  # The recipe's own agent-browser calls inherit the port's session, profile and executable.
  out=$(ab_env "$port"; cd "$(toplevel "$PWD")" && bash -c "$c" </dev/null 2>&1); rc=$?
  if [ "$rc" -ne 0 ]; then say "LOGIN_FAILED exit=$rc"; say "$out" | tail -5; return 1; fi
  url=$(cmd_ab "$port" get url 2>/dev/null | tail -1)
  say "LOGGED_IN user=${user:-?} url=$url"
  say "$out" | tail -3
}
cmd_dash() {
  local port="${DEV_UP_AB_DASH_PORT:-4848}"
  if ! bound "$port"; then agent-browser dashboard start --port "$port" >/dev/null 2>&1 || die 3 "dashboard did not start"; fi
  say "DASH url=http://localhost:$port"
}
cmd_browser() { ( ab_env "$1"; say "mode=$(ab_mode "$1") session=$AGENT_BROWSER_SESSION exe=${AGENT_BROWSER_EXECUTABLE_PATH:-} profile=$AGENT_BROWSER_PROFILE alive=$(ab_alive "$1" && echo yes || echo no)" ); }

cmd="${1:-}"; [ $# -gt 0 ] && shift
if [ "$cmd" != unwatched ] && [ -n "$SELF" ] && [ "$SELF" != "$CACHE/dev-up.sh" ]; then
  mkdir -p "$CACHE" && ln -sf "$SELF" "$CACHE/dev-up.sh"
fi
if [ "$SKILL" = dev-up ]; then
  case "$cmd" in
    owner|preflight|serve|wait|logs|watch|stop|state|unwatched|-h|--help|help|'') ;;
    *) say "dev-up: unknown command '$cmd'"; usage; exit 2 ;;
  esac
fi
case "$cmd" in
  owner|serve|wait|logs|watch|stop|state|ab|show|hide|browser|login) need_port "${1:-}" ;;
esac
case "$cmd" in
  owner) cmd_owner "$1" ;;
  preflight) cmd_preflight "${1:-}" ;;
  serve) cmd_serve "$@" ;;
  wait) cmd_wait "$1" ;;
  logs) case "${2:-40}" in ''|*[!0-9]*) die 2 "logs PORT [N]: N must be a number" ;; esac
        tail -n "${2:-40}" "$(f "$1" log)" 2>/dev/null || die 1 "no log for port $1" ;;
  watch) cmd_watch "$1" ;;
  stop) cmd_stop "$1" "${2:-}" ;;
  state) cmd_state "$@" ;;
  unwatched) cmd_unwatched ;;
  ab) cmd_ab "$@" ;;
  show) cmd_switch "$1" headed ;;
  hide) cmd_switch "$1" headless ;;
  login) cmd_login "$@" ;;
  recipe) cmd_recipe "$@" ;;
  dash) cmd_dash ;;
  browser) cmd_browser "$1" ;;
  -h|--help|help|'') usage ;;
  *) say "dev-up: unknown command '$cmd'"; usage; exit 2 ;;
esac
