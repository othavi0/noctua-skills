#!/usr/bin/env bash
# dev-up: the mechanical half of the dev-up skill. One dev server per port, one log, one state file.
#
# Usage: dev-up.sh <command> [PORT] [args]
#   owner PORT            FREE | BUSY pid=N cwd=DIR mine=yes|worktree|no|? via=dev-up|other state=mine|other|none
#   preflight [DIR]       what this checkout needs before launch: run/todo/warn lines
#   serve PORT [--dir DIR] [--mem SIZE] -- CMD
#                         run CMD (one shell string) in the foreground, logging to PORT.log.
#                         Call it with run_in_background: the task ends when the server dies.
#   wait PORT             READY http=N | HTTP_5XX http=N | DIED | BUSY_OTHER pid=N | BOUND_NO_HTTP | TIMEOUT
#   watch PORT            the Monitor command: new error lines from the log, minus noise and excludes
#   stop PORT [--force]   SIGTERM the server serve started: STOPPED | STILL_BOUND. --force: any listener
#   state PORT init | show | get KEY | set KEY=VALUE... | pause | exclude 'TEXT' | rm
#   unwatched             for the UserPromptSubmit hook: this session's dead servers and watchers
#
# Files in ~/.cache/dev-up: PORT.log, PORT.state (session dir server_task watcher_task tab_id),
# PORT.pid (serve), PORT.watch (watch), PORT.paused, PORT.exclude (fixed strings, one per line).
# Exit codes: 0 ok, 1 negative verdict, 2 usage, 3 refused.
set -uo pipefail

CACHE="${DEV_UP_CACHE:-$HOME/.cache/dev-up}"
KEYS="session dir server_task watcher_task tab_id"
ERRORS='[Ee]rror|Exception|Traceback|Failed to compile|unhandled|ECONNREFUSED|EADDRINUSE|panic|FATAL'
NOISE='NEXT_REDIRECT|PoolError|QueuePool limit|Too many connections|favicon\.ico|SIGTERM|terminated by signal|exit code 143|(GET|POST|PUT|PATCH|DELETE|HEAD|OPTIONS) [^ ]+( HTTP/[0-9.]+"?)? [23][0-9][0-9]([^0-9]|$)'

say() { printf '%s\n' "$*"; }
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

listener_pid() {
  if have ss; then ss -ltnpH "sport = :$1" 2>/dev/null | grep -oE 'pid=[0-9]+' | head -1 | cut -d= -f2
  else lsof -tnP -iTCP:"$1" -sTCP:LISTEN 2>/dev/null | head -1; fi
}

descends() {
  local p="$1" root="$2"
  while [ -n "$p" ] && [ "$p" -gt 1 ]; do
    [ "$p" = "$root" ] && return 0
    p=$(ps -o ppid= -p "$p" 2>/dev/null | tr -d ' ')
  done
  return 1
}

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
proc_cwd() { readlink -f "/proc/$1/cwd" 2>/dev/null || lsof -a -p "$1" -d cwd -Fn 2>/dev/null | sed -n 's/^n//p'; }

state_get() { sed -n "s/^$2=//p" "$(f "$1" state)" 2>/dev/null | tail -1; }
state_owner() {
  local s; s=$(state_get "$1" session)
  if [ ! -f "$(f "$1" state)" ]; then say none
  elif [ -n "$s" ] && [ "$s" = "$(session_id)" ]; then say mine
  else say other; fi
}
via() { local sp; sp=$(cat "$(f "$2" pid)" 2>/dev/null); alive "$sp" && descends "$1" "$sp" && say dev-up || say other; }

cmd_owner() {
  local port="$1" pid cwd here mine=no
  need_tool
  bound "$port" || { say FREE; return 0; }
  pid=$(listener_pid "$port")
  [ -n "$pid" ] || { say "BUSY pid=? cwd=? mine=? via=other state=$(state_owner "$port")"; return 1; }
  cwd=$(proc_cwd "$pid")
  here=$(toplevel "$PWD")
  if [ -n "$cwd" ] && [ "$(toplevel "$cwd")" = "$here" ]; then mine=yes
  elif [ -n "$cwd" ] && [ -n "$(common_dir "$PWD")" ] && [ "$(common_dir "$cwd")" = "$(common_dir "$PWD")" ]; then mine=worktree
  fi
  say "BUSY pid=$pid cwd=${cwd:-?} mine=$mine via=$(via "$pid" "$port") state=$(state_owner "$port")"
  return 1
}

q() { printf '%q' "$1"; }

cmd_preflight() {
  local dir top main wt=no lock="" mgr="" install=""
  dir=$(cd "${1:-$PWD}" && pwd -P) || die 2 "no such dir ${1:-}"
  top=$(toplevel "$dir")
  main=$(git -C "$dir" worktree list --porcelain 2>/dev/null | sed -n '1s/^worktree //p')
  [ -n "$main" ] && [ "$main" != "$top" ] && wt=yes
  say "ok checkout $top worktree=$wt"

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
  local port="$1" dir="$PWD" mem=""; shift
  while [ $# -gt 0 ]; do
    case "$1" in
      --dir) dir="${2:-}"; shift 2 ;;
      --mem) mem="${2:-}"; shift 2 ;;
      --) shift; break ;;
      *) die 2 "serve: unknown argument '$1' (the command goes after --)" ;;
    esac
  done
  [ $# -gt 0 ] || die 2 "serve: missing the command after --"
  mkdir -p "$CACHE"
  local log; log=$(f "$port" log)
  if bound "$port"; then say "dev-up serve: port $port is already bound; nothing started" >>"$log"; die 3 "port $port is already bound"; fi
  cd "$dir" 2>/dev/null || { say "dev-up serve: no such dir $dir" >>"$log"; die 2 "serve: no such dir $dir"; }
  [ -f "$log" ] && mv "$log" "$log.1"
  rm -f "$(f "$port" pid)"
  local top; top=$(toplevel "$PWD")
  PATH="$PWD/node_modules/.bin:$top/node_modules/.bin:$PATH"
  [ -d .venv/bin ] && PATH="$PWD/.venv/bin:$PATH"
  say $$ >"$(f "$port" pid)"
  if [ -n "$mem" ]; then exec systemd-run --user --scope --quiet -p MemoryMax="$mem" -- bash -c "$*" >>"$log" 2>&1; fi
  exec bash -c "$*" >>"$log" 2>&1
}

cmd_wait() {
  local port="$1" log pidf sp lp code end i=0
  log=$(f "$port" log); pidf=$(f "$port" pid)
  end=$(($(date +%s) + 240))
  while :; do
    sp=$(cat "$pidf" 2>/dev/null)
    if ! alive "$sp"; then
      i=$((i + 1))
      if [ $i -ge 10 ]; then say DIED; tail -20 "$log" 2>/dev/null; return 1; fi
    elif bound "$port"; then
      lp=$(listener_pid "$port")
      if [ -n "$lp" ] && ! descends "$lp" "$sp"; then say "BUSY_OTHER pid=$lp"; return 1; fi
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
  local port="$1" sp exc
  mkdir -p "$CACHE"
  say $$ >"$(f "$port" watch)"
  rm -f "$(f "$port" paused)"
  exc=$(f "$port" exclude); [ -f "$exc" ] || : >"$exc"
  : >>"$(f "$port" log)"
  sp=$(cat "$(f "$port" pid)" 2>/dev/null)
  if ! alive "$sp" || ! descends "$(listener_pid "$port")" "$sp"; then
    say "dev-up: port $port was not started by serve; this watcher reports only the server going down"
  fi
  trap 'pkill -P $$ 2>/dev/null; exit 0' TERM INT HUP
  ( while bound "$port"; do sleep 5; done; say "dev-up: SERVER DOWN on port $port" ) &
  tail -n 0 -F "$(f "$port" log)" 2>/dev/null \
    | grep -E --line-buffered "$ERRORS" \
    | grep -vE --line-buffered "$NOISE" \
    | grep -vF --line-buffered -f "$exc" &
  wait
}

cmd_stop() {
  local port="$1" force="${2:-}" sp lp p i
  need_tool
  sp=$(cat "$(f "$port" pid)" 2>/dev/null)
  bound "$port" || alive "$sp" || { say STOPPED; return 0; }
  lp=$(listener_pid "$port")
  if alive "$sp" && { [ -z "$lp" ] || descends "$lp" "$sp"; }; then
    for p in $(tree "$sp"); do kill -TERM "$p" 2>/dev/null; done
  elif [ "$force" = --force ]; then
    [ -n "$lp" ] || die 3 "cannot see the listener's pid (another user's process?)"
    for p in $(tree "$lp"); do kill -TERM "$p" 2>/dev/null; done
  else
    die 3 "port $port is held by pid ${lp:-?}, which serve did not start; ask the user, then use --force"
  fi
  for i in $(seq 20); do
    if ! bound "$port" && ! alive "$sp"; then rm -f "$(f "$port" pid)"; say STOPPED; return 0; fi
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
    exclude)
      local text="${1:?state PORT exclude 'TEXT'}" exc; exc=$(f "$port" exclude)
      [ "${#text}" -ge 4 ] || die 2 "exclude takes a literal piece of the log line, at least 4 characters"
      grep -qxF -e "$text" "$exc" 2>/dev/null || say "$text" >>"$exc"
      say "excluded (fixed string): $text" ;;
    show)
      [ -f "$sf" ] || { say "no state for $port"; return 1; }
      cat "$sf"
      local sp wp; sp=$(cat "$(f "$port" pid)" 2>/dev/null); wp=$(cat "$(f "$port" watch)" 2>/dev/null)
      say "server_alive=$(alive "$sp" && echo yes || echo no) watcher_alive=$(alive "$wp" && echo yes || echo no) paused=$([ -f "$(f "$port" paused)" ] && echo yes || echo no)"
      [ -s "$(f "$port" exclude)" ] && sed 's/^/excluded: /' "$(f "$port" exclude)"
      return 0 ;;
    rm) rm -f "$sf" "$(f "$port" pid)" "$(f "$port" watch)" "$(f "$port" paused)" "$(f "$port" exclude)" ;;
    *) die 2 "state: unknown op '$op'" ;;
  esac
}

cmd_unwatched() {
  local sid sf port wp
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
    if ! bound "$port"; then
      say "dev-up: the server on port $port is down (log: $(f "$port" log)). Its state is cleared; run /dev-up $port to bring it back."
      rm -f "$sf" "$(f "$port" pid)" "$(f "$port" watch)" "$(f "$port" paused)"
    elif ! alive "$wp" && [ ! -f "$(f "$port" paused)" ]; then
      say "dev-up: port $port has no live watcher; re-arm it (dev-up step 3) before answering."
    fi
  done
  return 0
}

cmd="${1:-}"; [ $# -gt 0 ] && shift
if [ "$cmd" != unwatched ] && self=$(readlink -f "$0" 2>/dev/null) && [ "$self" != "$CACHE/dev-up.sh" ]; then
  mkdir -p "$CACHE" && ln -sf "$self" "$CACHE/dev-up.sh"
fi
case "$cmd" in
  owner|serve|wait|watch|stop|state) need_port "${1:-}" ;;
esac
case "$cmd" in
  owner) cmd_owner "$1" ;;
  preflight) cmd_preflight "${1:-}" ;;
  serve) cmd_serve "$@" ;;
  wait) cmd_wait "$1" ;;
  watch) cmd_watch "$1" ;;
  stop) cmd_stop "$1" "${2:-}" ;;
  state) cmd_state "$@" ;;
  unwatched) cmd_unwatched ;;
  -h|--help|help|'') sed -n '2,19p' "$0" ;;
  *) say "dev-up: unknown command '$cmd'"; sed -n '4,15p' "$0"; exit 2 ;;
esac
