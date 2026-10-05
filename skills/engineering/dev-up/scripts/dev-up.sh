#!/usr/bin/env bash
# dev-up: the mechanical half of the dev-up skill. One dev server per port, one log, one state file.
#
# Usage: dev-up.sh <command> [PORT] [args]
#   owner PORT            FREE | BUSY pid=N cwd=DIR mine=yes|worktree|no|? | NOTOOL
#   preflight [DIR]       what this checkout needs before launch: deps, .venv, .env, pinned ports
#   serve PORT [--dir DIR] [--mem SIZE] -- CMD
#                         run CMD (one shell string) in the foreground, appending to the log.
#                         Call it with run_in_background so the task ends when the server dies.
#   wait PORT             block until the port answers HTTP: READY | DIED | NOBIND | BOUND_NO_HTTP
#   watch PORT            the Monitor command: error lines from the log, minus noise and `excluded`
#   stop PORT             free the port, only when the state says owner=self: STOPPED | STILL_BOUND
#   state PORT init owner=self|reused
#   state PORT get KEY | set KEY=VALUE... | exclude PATTERN | show | rm
#   unwatched             for the UserPromptSubmit hook: one line per port of this checkout whose
#                         server is down or whose watcher expired (silent when all is well)
#
# Files: ~/.cache/dev-up/PORT.log and ~/.cache/dev-up/PORT.state (key=value lines).
# Exit codes: 0 ok, 1 negative result (DIED, BUSY, ...), 2 usage, 3 refused.
set -uo pipefail

CACHE="${DEV_UP_CACHE:-$HOME/.cache/dev-up}"
KEYS="port owner dir started server_task watcher_task watcher_until tab_id excluded"
ERRORS='[Ee]rror|Exception|Traceback|Failed to compile|unhandled|ECONNREFUSED|EADDRINUSE|panic|FATAL'
NOISE='NEXT_REDIRECT|PoolError|QueuePool limit|Too many connections|favicon\.ico|(GET|POST|PUT|PATCH|DELETE|HEAD|OPTIONS) [^ ]+( HTTP/[0-9.]+"?)? [23][0-9]{2}\b'
DEAD='FATAL|panic:|panicked at|command not found|Cannot find module|ModuleNotFoundError|ImportError|EADDRINUSE|address already in use|Traceback \(most recent call last\)|exited with code [1-9]|ELIFECYCLE'
MARK='--- dev-up serve '

say() { printf '%s\n' "$*"; }
die() { local code="$1"; shift; say "ERROR: $*" >&2; exit "$code"; }
have() { command -v "$1" >/dev/null 2>&1; }
need_port() { case "${1:-}" in ''|*[!0-9]*) die 2 "PORT must be a number, got '${1:-}'";; esac; }

bound() {
  if have ss; then [ -n "$(ss -ltnH "sport = :$1" 2>/dev/null)" ]
  else lsof -nP -iTCP:"$1" -sTCP:LISTEN >/dev/null 2>&1; fi
}

listener_pid() {
  if have ss; then ss -ltnpH "sport = :$1" 2>/dev/null | grep -oE 'pid=[0-9]+' | head -1 | cut -d= -f2
  else lsof -tnP -iTCP:"$1" -sTCP:LISTEN 2>/dev/null | head -1; fi
}

toplevel() { git -C "$1" rev-parse --show-toplevel 2>/dev/null || readlink -f "$1"; }
common_dir() { git -C "$1" rev-parse --path-format=absolute --git-common-dir 2>/dev/null; }

cmd_owner() {
  local port="$1" pid cwd here
  have ss || have lsof || { say NOTOOL; exit 2; }
  bound "$port" || { say FREE; return 0; }
  pid=$(listener_pid "$port")
  [ -n "$pid" ] || { say "BUSY pid=? cwd=? mine=?"; return 1; }
  cwd=$(readlink -f "/proc/$pid/cwd" 2>/dev/null || lsof -a -p "$pid" -d cwd -Fn 2>/dev/null | sed -n 's/^n//p')
  here=$(toplevel "$PWD")
  local mine=no
  case "$cwd/" in "$here"/*) mine=yes ;; esac
  if [ "$mine" = no ] && [ -n "$cwd" ] && [ -n "$(common_dir "$PWD")" ] && [ "$(common_dir "$cwd")" = "$(common_dir "$PWD")" ]; then
    mine=worktree
  fi
  say "BUSY pid=$pid cwd=${cwd:-?} mine=$mine"
  return 1
}

lock_manager() {
  local d="$1"
  if [ -f "$d/bun.lock" ] || [ -f "$d/bun.lockb" ]; then say "bun bun.lock bun install --frozen-lockfile"
  elif [ -f "$d/pnpm-lock.yaml" ]; then say "pnpm pnpm-lock.yaml pnpm install --frozen-lockfile"
  elif [ -f "$d/yarn.lock" ]; then say "yarn yarn.lock yarn install --frozen-lockfile"
  elif [ -f "$d/package-lock.json" ]; then say "npm package-lock.json npm ci"
  fi
}

cmd_preflight() {
  local dir top main rel
  dir=$(readlink -f "${1:-$PWD}")
  top=$(toplevel "$dir")
  main=$(git -C "$dir" worktree list --porcelain 2>/dev/null | sed -n '1s/^worktree //p')
  rel=${dir#"$top"}; rel=${rel#/}
  local wt=no
  [ -n "$main" ] && [ "$main" != "$top" ] && wt=yes
  say "checkout $top worktree=$wt${main:+ main=$main}"

  if [ -f "$dir/package.json" ] || [ -f "$top/package.json" ]; then
    local lm mgr lockf install
    lm=$(lock_manager "$top"); [ -n "$lm" ] || lm=$(lock_manager "$dir")
    if [ -n "$lm" ]; then
      read -r mgr lockf install <<<"$lm"
      local runner
      case "$mgr" in bun) runner="bun x" ;; pnpm) runner="pnpm exec" ;; yarn) runner="yarn" ;; *) runner="npx" ;; esac
      say "ok manager=$mgr: launch with '$mgr run dev', or run a bin with '$runner <bin>'"
    fi
    local pj="$dir/package.json"; [ -f "$pj" ] || pj="$top/package.json"
    grep -E '"dev"[[:space:]]*:' "$pj" | sed 's/^[[:space:]]*/ok dev script: /'
    if [ -d "$dir/node_modules" ] || [ -d "$top/node_modules" ]; then
      say "ok node_modules present"
    elif [ "$wt" = yes ] && [ -n "${lockf:-}" ]; then
      local turbo=no
      grep -qE '"next"[[:space:]]*:[[:space:]]*"[~^]?(1[6-9]|[2-9][0-9])|--turbo' "$pj" "$top/package.json" 2>/dev/null && turbo=yes
      if [ -d "$main/node_modules" ] && [ "$turbo" = no ] && cmp -s "$top/$lockf" "$main/$lockf"; then
        say "do ln -s $main/node_modules $top/node_modules   # lockfile matches main"
      else
        say "do (cd $top && $install)   # turbopack=$turbo, lockfile $(cmp -s "$top/$lockf" "$main/$lockf" && echo matches || echo differs from) main; a symlink breaks Turbopack"
      fi
    else
      say "do (cd $top && ${install:-<package manager> install})"
    fi
  fi

  if [ -f "$dir/pyproject.toml" ] || [ -f "$dir/requirements.txt" ]; then
    if [ -d "$dir/.venv" ]; then say "ok .venv present; serve puts .venv/bin first on PATH"
    elif [ "$wt" = yes ] && [ -d "$main/$rel/.venv" ]; then say "do ln -s $main/$rel/.venv $dir/.venv"
    else say "do create $dir/.venv and install the project's requirements"
    fi
  fi

  if [ "$wt" = yes ]; then
    local f
    for f in .env .env.local .env.development .env.development.local; do
      [ -e "$dir/$f" ] || [ ! -f "$main/$rel/$f" ] || say "do ln -s $main/$rel/$f $dir/$f   # gitignored, missing in this worktree"
    done
  fi

  local hits
  hits=$(grep -HnoE '^[A-Za-z_][A-Za-z0-9_]*=.*localhost:[0-9]+' "$dir"/.env* "$top"/.env* 2>/dev/null | sort -u)
  [ -n "$hits" ] && printf '%s\n' "$hits" | sed 's/^/warn pinned port: /'
  return 0
}

cmd_serve() {
  local port="$1"; shift
  local dir="$PWD" mem=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --dir) dir="${2:-}"; shift 2 ;;
      --mem) mem="${2:-}"; shift 2 ;;
      --) shift; break ;;
      *) die 2 "serve: unknown argument '$1' (the command goes after --)" ;;
    esac
  done
  [ $# -gt 0 ] || die 2 "serve: missing the command after --"
  bound "$port" && die 3 "port $port is already bound; run 'owner $port'"
  cd "$dir" || die 2 "serve: no such dir $dir"
  mkdir -p "$CACHE"
  local log="$CACHE/$port.log"
  [ -d .venv/bin ] && PATH="$PWD/.venv/bin:$PATH"
  printf '%s%s %s ---\n' "$MARK" "$(now_iso)" "$PWD" >>"$log"
  if [ -n "$mem" ]; then
    exec systemd-run --user --scope --quiet -p MemoryMax="$mem" -- bash -c "$*" >>"$log" 2>&1
  fi
  exec bash -c "$*" >>"$log" 2>&1
}

since_mark() { awk -v m="$MARK" 'index($0, m) == 1 { buf = "" } { buf = buf $0 ORS } END { printf "%s", buf }' "$1" 2>/dev/null; }
now_iso() { date +%Y-%m-%dT%H:%M:%S%z; }

cmd_wait() {
  local port="$1" log="$CACHE/$1.log" i=0 size last=-1 dead
  until bound "$port"; do
    dead=$(since_mark "$log" | grep -nE "$DEAD" | tail -5)
    if [ -n "$dead" ]; then say DIED; printf '%s\n' "$dead"; return 1; fi
    size=$(wc -c <"$log" 2>/dev/null || echo 0)
    if [ "$size" != "$last" ]; then last=$size; i=0; else i=$((i + 1)); fi
    if [ $i -ge 60 ]; then say "NOBIND (log quiet for 30s)"; since_mark "$log" | tail -20; return 1; fi
    sleep 0.5
  done
  local code
  code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 300 --retry 60 --retry-connrefused --retry-delay 1 "http://localhost:$port/")
  if [ -n "$code" ] && [ "$code" != 000 ]; then say "READY http=$code"; return 0; fi
  say BOUND_NO_HTTP; since_mark "$log" | tail -20; return 1
}

cmd_watch() {
  local port="$1" exc
  exc=$(state_get "$port" excluded)
  tail -n 0 -F "$CACHE/$port.log" 2>/dev/null \
    | grep -E --line-buffered "$ERRORS" \
    | grep -vE --line-buffered "$NOISE${exc:+|$exc}"
}

cmd_stop() {
  local port="$1" i
  [ "$(state_get "$port" owner)" = self ] || die 3 "owner is not self in $CACHE/$port.state; this session did not start the server"
  bound "$port" || { say STOPPED; return 0; }
  if have fuser && [ "$(uname)" = Linux ]; then fuser -k "$port/tcp" >/dev/null 2>&1
  else listener_pid "$port" | xargs kill 2>/dev/null; fi
  for i in $(seq 20); do bound "$port" || { say STOPPED; return 0; }; sleep 0.5; done
  say "STILL_BOUND (something respawns it; tell the user)"; return 1
}

state_file() { say "$CACHE/$1.state"; }
state_get() { sed -n "s/^$2=//p" "$(state_file "$1")" 2>/dev/null | tail -1; }

state_write() {
  local sf; sf=$(state_file "$1"); shift
  local tmp; tmp=$(mktemp "$sf.XXXXXX") || die 3 "cannot write $sf"
  local drop="" kv
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
    owner) case "$v" in self|reused) ;; *) die 2 "owner is self or reused, got '$v'" ;; esac ;;
  esac
}

cmd_state() {
  local port="$1" op="${2:-show}"; shift 2 2>/dev/null || shift $#
  mkdir -p "$CACHE"
  case "$op" in
    init)
      [ $# -eq 1 ] || die 2 "state PORT init owner=self|reused"
      check_kv "$1"
      rm -f "$(state_file "$port")"
      state_write "$port" "port=$port" "$1" "dir=$(toplevel "$PWD")" "started=$(now_iso)" ;;
    get) state_get "$port" "${1:?state PORT get KEY}" ;;
    set)
      [ $# -gt 0 ] || die 2 "state PORT set KEY=VALUE..."
      [ -f "$(state_file "$port")" ] || die 3 "no state for $port; run 'state $port init owner=...' first"
      local kv extra=()
      for kv in "$@"; do
        check_kv "$kv"
        case "$kv" in
          watcher_task=?*) extra+=("watcher_until=$(($(date +%s) + 1800))") ;;
          watcher_task=) extra+=("watcher_until=") ;;
        esac
      done
      state_write "$port" "$@" "${extra[@]}" ;;
    exclude)
      local pat="${1:?state PORT exclude PATTERN}" cur
      cur=$(state_get "$port" excluded)
      case "|$cur|" in *"|$pat|"*) return 0 ;; esac
      state_write "$port" "excluded=${cur:+$cur|}$pat" ;;
    show) cat "$(state_file "$port")" 2>/dev/null || { say "no state for $port"; return 1; } ;;
    rm) rm -f "$(state_file "$port")" "$CACHE/$port.log" ;;
    *) die 2 "state: unknown op '$op'" ;;
  esac
}

cmd_unwatched() {
  local sf port here exp
  here=$(toplevel "$PWD")
  for sf in "$CACHE"/*.state; do
    [ -f "$sf" ] || continue
    port=$(basename "$sf" .state)
    [ "$(state_get "$port" dir)" = "$here" ] || continue
    exp=$(state_get "$port" watcher_until)
    if ! bound "$port"; then
      say "dev-up: the server on port $port is down; restart it or run 'dev-up.sh state $port rm'"
    elif [ -z "$exp" ] || [ "$(date +%s)" -ge "$exp" ]; then
      say "dev-up: port $port has no live watcher; re-arm it (dev-up skill, step 3) before answering"
    fi
  done
  return 0
}

cmd="${1:-}"; [ $# -gt 0 ] && shift
case "$cmd" in
  owner|serve|wait|watch|stop|state) need_port "${1:-}" ;;
esac
case "$cmd" in
  owner) cmd_owner "$1" ;;
  preflight) cmd_preflight "${1:-}" ;;
  serve) cmd_serve "$@" ;;
  wait) cmd_wait "$1" ;;
  watch) cmd_watch "$1" ;;
  stop) cmd_stop "$1" ;;
  state) cmd_state "$@" ;;
  unwatched) cmd_unwatched ;;
  -h|--help|help|'') sed -n '2,20p' "$0" ;;
  *) say "dev-up: unknown command '$cmd'"; sed -n '4,16p' "$0"; exit 2 ;;
esac
