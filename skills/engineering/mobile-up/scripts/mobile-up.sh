#!/usr/bin/env bash
# mobile-up — bring up the dev server + Metro (+ Android emulator) for an Expo app,
# with the LAN IP synced into the app's env and proof that each piece answers.
#
# Usage: mobile-up.sh [server|app|emulator|status] [--server-port N] [--metro-port N] [--take-emulator]
#   server    dev server only
#   app       dev server + Metro (default) — test on a phone with Expo Go
#   emulator  dev server + Metro + Android emulator, app opened with a fresh bundle
#   status    who holds the ports, env vs bundle, devices — changes nothing
#   --take-emulator   replace an app another Metro opened on the emulator (ask the user first)
#
# Exit codes: 0 ok · 2 usage/platform · 3 project not detected or preflight failed
#             4 server failed · 5 metro failed · 6 emulator failed
#
# Linux only (needs ss, ip, /proc). Never kills anything.
set -uo pipefail

# ----------------------------------------------------------------------------- helpers
say() { printf '%s\n' "$*"; }
warn() { WARNINGS="${WARNINGS}  - $*"$'\n'; say "warning: $*"; }
die() { local code="$1"; shift; say "ERROR: $*"; exit "$code"; }
have() { command -v "$1" >/dev/null 2>&1; }

# ----------------------------------------------------------------------------- args
TARGET="app"
SERVER_PORT_ARG=""
METRO_PORT_ARG=""
TAKE_EMULATOR=0
while [ $# -gt 0 ]; do
  case "$1" in
    server|app|emulator|status) TARGET="$1" ;;
    --server-port) SERVER_PORT_ARG="${2:-}"; case "$SERVER_PORT_ARG" in ''|*[!0-9]*) die 2 "--server-port needs a number, got '${SERVER_PORT_ARG}'";; esac; shift ;;
    --metro-port) METRO_PORT_ARG="${2:-}"; case "$METRO_PORT_ARG" in ''|*[!0-9]*) die 2 "--metro-port needs a number, got '${METRO_PORT_ARG}'";; esac; shift ;;
    --take-emulator) TAKE_EMULATOR=1 ;;
    -h|--help) sed -n '2,15p' "$0"; exit 0 ;;
    *) printf 'mobile-up: unknown argument "%s"\n' "$1"; sed -n '5,10p' "$0"; exit 2 ;;
  esac
  shift
done

age_h() { # seconds -> "1h12m" / "43s"
  local s="${1:-0}"
  if [ "$s" -ge 3600 ]; then printf '%dh%02dm' $((s / 3600)) $(((s % 3600) / 60))
  elif [ "$s" -ge 60 ]; then printf '%dm%02ds' $((s / 60)) $((s % 60))
  else printf '%ds' "$s"; fi
}

conf_get() { # file key -> value (KEY=value, optional quotes; last one wins)
  [ -f "$1" ] || return 1
  grep -E "^[[:space:]]*$2[[:space:]]*=" "$1" 2>/dev/null | tail -1 \
    | sed -E "s/^[[:space:]]*$2[[:space:]]*=[[:space:]]*//; s/^\"(.*)\"[[:space:]]*$/\1/; s/^'(.*)'[[:space:]]*$/\1/"
}

port_listening() { ss -ltnH "sport = :$1" 2>/dev/null | grep -q LISTEN; }
port_pid() { ss -ltnpH "sport = :$1" 2>/dev/null | grep -oP 'pid=\K[0-9]+' | head -1; }
pid_cwd() { readlink "/proc/$1/cwd" 2>/dev/null || printf '?'; }
pid_age() { ps -o etimes= -p "$1" 2>/dev/null | tr -d ' '; }
pid_start() { ps -o lstart= -p "$1" 2>/dev/null; }
pid_start_epoch() { local s; s="$(pid_start "$1")"; [ -n "$s" ] || { printf 0; return; }; date -d "$s" +%s 2>/dev/null || printf 0; }

cwd_is_ours() { # cwd -> 0 if under ROOT
  local c; c="$(realpath -m "$1" 2>/dev/null || printf '%s' "$1")"
  case "$c" in "$ROOT" | "$ROOT"/*) return 0 ;; esac
  return 1
}

free_port_after() { # base -> first free port above base (max +20)
  local p="$1" i
  for i in $(seq 1 20); do
    p=$((p + 1))
    port_listening "$p" || { printf '%s' "$p"; return 0; }
  done
  return 1
}

log_excerpt() { # logfile
  say "  errors in $1:"
  grep -aiE 'error|EADDRINUSE|cannot|failed|missing|not found|unable' "$1" 2>/dev/null | tr -d '\000' | tail -8 | sed 's/^/    /'
  say "  last lines:"
  tail -12 "$1" 2>/dev/null | tr -d '\000' | sed 's/^/    /'
}

launch() { # dir logfile command... -> pid  (detached: survives this shell and the agent's)
  local dir="$1" log="$2"; shift 2
  (
    cd "$dir" || exit 1
    export PATH="$dir/node_modules/.bin:$ROOT/node_modules/.bin:$PATH"
    nohup setsid "$@" > "$log" 2>&1 < /dev/null &
    printf '%s' "$!"
  )
}

wait_bind() { # port timeout_s pid -> 0 bound · 1 timeout · 2 process died
  local i=0 max=$(($2 * 2))
  until port_listening "$1"; do
    kill -0 "$3" 2>/dev/null || return 2
    i=$((i + 1))
    [ "$i" -ge "$max" ] && return 1
    sleep 0.5
  done
  return 0
}

http_code() { local c; c="$(curl -s -o /dev/null -m 5 -w '%{http_code}' "$1" 2>/dev/null)"; printf '%s' "${c:-000}"; }

wait_http() { # url timeout_s pid -> code ("000" on timeout, "died" if the process exited)
  local i=0 code
  while [ "$i" -lt "$2" ]; do
    code="$(http_code "$1")"
    [ "$code" != "000" ] && { printf '%s' "$code"; return 0; }
    kill -0 "$3" 2>/dev/null || { printf 'died'; return 0; }
    i=$((i + 1)); sleep 1
  done
  printf '000'
}

find_sdk() { # -> SDK root with platform-tools/adb, from machine.conf, env, ~/Android/Sdk, adb on PATH
  local d
  d="$(conf_get "$MCONF" ANDROID_HOME || true)"
  [ -n "$d" ] && [ -x "$d/platform-tools/adb" ] && { printf '%s' "$d"; return 0; }
  for d in "${ANDROID_HOME:-}" "${ANDROID_SDK_ROOT:-}" "$HOME/Android/Sdk"; do
    [ -n "$d" ] && [ -x "$d/platform-tools/adb" ] && { printf '%s' "$d"; return 0; }
  done
  have adb && { printf '%s' "$(dirname "$(dirname "$(readlink -f "$(command -v adb)")")")"; return 0; }
  return 1
}

expo_go_compatible() { # expo_go_version project_sdk_major -> 0 compatible, 1 incompatible, 2 unknown (skip warning)
  local ver="$1" sdk="$2" vmajor="${1%%.*}" vminor
  vminor="$(printf '%s' "$ver" | cut -d. -f2)"
  case "$sdk" in
    51|52|53) # SDK 51-53 shipped Expo Go as androidClientVersion 2.3X.y, X = sdk - 20
      [ -z "$vmajor" ] && return 2
      [ "$vmajor" = 2 ] && [ "$vminor" = "$((sdk - 20))" ] && return 0
      return 1 ;;
    *) # SDK 54+: Expo Go's own version tracks the project SDK major directly
      [ -z "$vmajor" ] && return 2
      [ "$vmajor" = "$sdk" ] && return 0
      return 1 ;;
  esac
}

find_ours_port() { # base -> port in [base, base+20] whose listener runs under ROOT (our earlier run), or nothing
  local p="$1" i pid
  for i in $(seq 0 20); do
    pid="$(port_pid $((p + i)))"
    [ -n "$pid" ] && cwd_is_ours "$(pid_cwd "$pid")" && { printf '%s' $((p + i)); return 0; }
  done
  return 1
}

# ----------------------------------------------------------------------------- platform
[ "$(uname -s)" = "Linux" ] || die 2 "mobile-up.sh supports Linux only for now (needs ss, ip, /proc). See references/config.md."
for t in ss ip curl; do have "$t" || die 2 "missing tool: $t"; done

# ----------------------------------------------------------------------------- project
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
ROOT="$(realpath "$ROOT")"
SLUG="$(basename "$ROOT")"
MAIN_WT="$(git -C "$ROOT" worktree list --porcelain 2>/dev/null | awk '/^worktree /{print $2; exit}')"
if [ -n "$MAIN_WT" ] && [ "$(realpath "$MAIN_WT" 2>/dev/null)" != "$ROOT" ]; then SLUG="$(basename "$MAIN_WT")-$SLUG"; fi   # linked worktree: clock-in-feature
CACHE="$HOME/.cache/mobile-up"; mkdir -p "$CACHE"
CONF="$ROOT/.claude/mobile-up.conf"
MCONF="${XDG_CONFIG_HOME:-$HOME/.config}/mobile-up/machine.conf"
STATE="$CACHE/$SLUG.state"
LOG_SERVER="$CACHE/$SLUG-server.log"
LOG_METRO="$CACHE/$SLUG-metro.log"
LOG_AVD="$CACHE/$SLUG-avd.log"
WARNINGS=""
EXIT=0

# package manager from lockfile
PM="npm"
if [ -f "$ROOT/bun.lock" ] || [ -f "$ROOT/bun.lockb" ]; then PM="bun"
elif [ -f "$ROOT/pnpm-lock.yaml" ]; then PM="pnpm"
elif [ -f "$ROOT/yarn.lock" ]; then PM="yarn"; fi
PM="$(conf_get "$CONF" PM || printf '%s' "$PM")"

# app (Expo) directory
APP_DIR="$(conf_get "$CONF" APP_DIR || true)"
if [ -n "$APP_DIR" ]; then
  APP_DIR="$ROOT/${APP_DIR#"$ROOT"/}"
else
  CANDS="$(find "$ROOT" -maxdepth 3 -name package.json -not -path '*/node_modules/*' -print0 2>/dev/null \
    | xargs -0 grep -lE '"expo"[[:space:]]*:' 2>/dev/null | xargs -r -n1 dirname)"
  N=$(printf '%s\n' "$CANDS" | grep -c . || true)
  if [ "$N" -eq 0 ]; then die 3 "no Expo app found under $ROOT (no package.json depending on \"expo\"). Not an Expo project, or set APP_DIR in $CONF."
  elif [ "$N" -gt 1 ]; then say "ERROR: several Expo apps found:"; printf '%s\n' "$CANDS" | sed 's/^/  /'; die 3 "set APP_DIR=<dir> in $CONF (ask the user which one)."
  fi
  APP_DIR="$CANDS"
fi
[ -f "$APP_DIR/package.json" ] || die 3 "APP_DIR $APP_DIR has no package.json"

# dev server: directory, dev script, port
SERVER="$(conf_get "$CONF" SERVER || true)"          # "none" disables the server
SERVER_DIR="$(conf_get "$CONF" SERVER_DIR || true)"
SERVER_CMD="$(conf_get "$CONF" SERVER_CMD || true)"
SERVER_PORT="$(conf_get "$CONF" SERVER_PORT || true)"
DEV_SCRIPT=""
if [ "$SERVER" != "none" ]; then
  if [ -z "$SERVER_DIR" ]; then
    ROOT_HAS_WS=0; grep -qE '"workspaces"' "$ROOT/package.json" 2>/dev/null && ROOT_HAS_WS=1
    SCANDS=""
    while IFS= read -r pj; do
      d="$(dirname "$pj")"
      [ "$d" = "$APP_DIR" ] && continue
      [ "$d" = "$ROOT" ] && [ "$ROOT_HAS_WS" -eq 1 ] && continue
      grep -qE '"dev"[[:space:]]*:' "$pj" || continue
      SCANDS="${SCANDS}${d}"$'\n'
    done < <(find "$ROOT" -maxdepth 3 -name package.json -not -path '*/node_modules/*' 2>/dev/null)
    SCANDS="$(printf '%s' "$SCANDS" | grep . || true)"
    N=$(printf '%s\n' "$SCANDS" | grep -c . || true)
    if [ "$N" -gt 1 ]; then # prefer a known server framework
      PREF="$(printf '%s\n' "$SCANDS" | while IFS= read -r d; do grep -qE '"(next|hono|express|fastify|@nestjs/core|koa)"[[:space:]]*:' "$d/package.json" && printf '%s\n' "$d"; done)"
      [ "$(printf '%s\n' "$PREF" | grep -c .)" -eq 1 ] && SCANDS="$PREF"
      N=$(printf '%s\n' "$SCANDS" | grep -c . || true)
    fi
    if [ "$N" -eq 0 ]; then
      SERVER="none"; warn "no dev server workspace found: Metro only (set SERVER_DIR in $CONF if the app talks to a local API)"
    elif [ "$N" -gt 1 ]; then
      say "ERROR: several dev-server candidates:"; printf '%s\n' "$SCANDS" | sed 's/^/  /'; die 3 "set SERVER_DIR=<dir> (or SERVER=none) in $CONF (ask the user which one)."
    else
      SERVER_DIR="$SCANDS"
    fi
  else
    SERVER_DIR="$ROOT/${SERVER_DIR#"$ROOT"/}"
  fi
fi
if [ "$SERVER" != "none" ]; then
  DEV_SCRIPT="$(grep -oP '"dev"\s*:\s*"\K[^"]*' "$SERVER_DIR/package.json" 2>/dev/null | head -1)"
  if [ -z "$SERVER_PORT" ]; then
    SERVER_PORT="$(printf '%s' "$DEV_SCRIPT $SERVER_CMD" | grep -oP -- '(--port[= ]|-p |PORT=)\K[0-9]+' | head -1)"
    if [ -z "$SERVER_PORT" ]; then
      if grep -qE '"next"[[:space:]]*:' "$SERVER_DIR/package.json"; then SERVER_PORT=3000
      elif grep -qE '"vite"[[:space:]]*:' "$SERVER_DIR/package.json"; then SERVER_PORT=5173
      else die 3 "cannot tell the dev server port from $SERVER_DIR (dev script: '${DEV_SCRIPT:-none}'). Set SERVER_PORT in $CONF."; fi
    fi
  fi
fi
SERVER_PORT_BASE="${SERVER_PORT_ARG:-$SERVER_PORT}"

# metro port
METRO_PORT="$(conf_get "$CONF" METRO_PORT || true)"
APP_DEV_SCRIPT="$(grep -oP '"dev"\s*:\s*"\K[^"]*' "$APP_DIR/package.json" 2>/dev/null | head -1)"
[ -z "$METRO_PORT" ] && METRO_PORT="$(printf '%s' "$APP_DEV_SCRIPT" | grep -oP -- '--port[= ]\K[0-9]+' | head -1)"
METRO_PORT_BASE="${METRO_PORT_ARG:-${METRO_PORT:-8081}}"

# env file and URL variable
ENV_FILE="$(conf_get "$CONF" ENV_FILE || printf '%s' "$APP_DIR/.env")"
ENV_FILE="$ROOT/${ENV_FILE#"$ROOT"/}"
ENV_VAR="$(conf_get "$CONF" ENV_VAR || true)"
if [ -z "$ENV_VAR" ] && [ "$SERVER" != "none" ]; then
  for f in "$ENV_FILE" "$APP_DIR/.env.example"; do
    [ -f "$f" ] || continue
    VARS="$(grep -oE '^EXPO_PUBLIC_[A-Z0-9_]*URL' "$f" | sort -u)"
    N=$(printf '%s\n' "$VARS" | grep -c . || true)
    if [ "$N" -eq 1 ]; then ENV_VAR="$VARS"; break
    elif [ "$N" -gt 1 ]; then say "ERROR: several URL variables in $f:"; printf '%s\n' "$VARS" | sed 's/^/  /'; die 3 "set ENV_VAR=<name> in $CONF (ask the user which one is the dev server)."; fi
  done
  [ -z "$ENV_VAR" ] && warn "no EXPO_PUBLIC_*URL variable in $ENV_FILE or .env.example: env sync skipped (set ENV_VAR in $CONF)"
fi

SERVER_TIMEOUT="$(conf_get "$CONF" SERVER_TIMEOUT || printf 90)"
METRO_TIMEOUT="$(conf_get "$CONF" METRO_TIMEOUT || printf 120)"
BOOT_TIMEOUT="$(conf_get "$CONF" BOOT_TIMEOUT || printf 360)"
case "$SERVER_TIMEOUT" in *[!0-9]*|'') warn "SERVER_TIMEOUT '$SERVER_TIMEOUT' in $CONF is not a number; using the default of 90s"; SERVER_TIMEOUT=90 ;; esac
case "$METRO_TIMEOUT" in *[!0-9]*|'') warn "METRO_TIMEOUT '$METRO_TIMEOUT' in $CONF is not a number; using the default of 120s"; METRO_TIMEOUT=120 ;; esac
case "$BOOT_TIMEOUT" in *[!0-9]*|'') warn "BOOT_TIMEOUT '$BOOT_TIMEOUT' in $CONF is not a number; using the default of 360s"; BOOT_TIMEOUT=360 ;; esac

# ----------------------------------------------------------------------------- network
IP="${MOBILE_UP_IP:-}"
IP_DEV=""; IP_NET=""
if [ -z "$IP" ]; then
  ROUTE="$(ip -4 route get 1.1.1.1 2>/dev/null | head -1)"
  IP="$(printf '%s' "$ROUTE" | grep -oP 'src \K\S+')"
  IP_DEV="$(printf '%s' "$ROUTE" | grep -oP 'dev \K\S+')"
fi
if [ -n "$IP" ] && [ -n "$IP_DEV" ]; then
  IP_NET="$(ip -o -4 route show dev "$IP_DEV" scope link 2>/dev/null | awk '{print $1}' | head -1)"
  case "$IP_DEV" in tun*|wg*|tailscale*|ppp*|utun*|zt*|nordlynx*|proton*)
    warn "default route goes through $IP_DEV (VPN?): $IP may be unreachable from a phone on the Wi-Fi. Override with MOBILE_UP_IP=<lan-ip>." ;;
  esac
fi
[ -z "$IP" ] && [ "$TARGET" = "app" ] && warn "no LAN IP (no default route?): the exp:// URL and QR below will be missing the host address"

# ----------------------------------------------------------------------------- state (previous run)
prev() { conf_get "$STATE" "$1" || true; }

# ----------------------------------------------------------------------------- status target
owner_line() { # port label
  local pid; pid="$(port_pid "$1")"
  if [ -z "$pid" ]; then
    if port_listening "$1"; then say "$2 :$1  LISTEN, owner not visible (another user?)"; else say "$2 :$1  free"; fi
    return
  fi
  local cwd; cwd="$(pid_cwd "$pid")"
  local who="foreign"; cwd_is_ours "$cwd" && who="this project"
  say "$2 :$1  pid $pid  $who  cwd $cwd  up $(age_h "$(pid_age "$pid")")  since $(pid_start "$pid")"
}

if [ "$TARGET" = "status" ]; then
  say "== mobile-up status ($SLUG) =="
  say "root     $ROOT"
  say "app      ${APP_DIR#"$ROOT"/}   pm $PM"
  [ "$SERVER" != "none" ] && say "server   ${SERVER_DIR#"$ROOT"/}   dev script: ${DEV_SCRIPT:-?}"
  say "ip       ${IP:-none}${IP_DEV:+ via $IP_DEV}${IP_NET:+ net $IP_NET}"
  [ "$SERVER" != "none" ] && owner_line "$SERVER_PORT_BASE" "server  "
  owner_line "$METRO_PORT_BASE" "metro   "
  if port_listening "$METRO_PORT_BASE"; then
    say "metro    /status → $(curl -s -m 2 "http://localhost:$METRO_PORT_BASE/status" 2>/dev/null || printf 'no answer')"
  fi
  if [ -n "$ENV_VAR" ]; then
    CUR="$(grep -E "^${ENV_VAR}=" "$ENV_FILE" 2>/dev/null | tail -1 | cut -d= -f2- | tr -d '\r"')"
    say "env      $ENV_VAR=${CUR:-<absent>}  (${ENV_FILE#"$ROOT"/})"
    say "bundle   Metro started with: $(prev METRO_URL)  (from $STATE, empty = not started by mobile-up)"
  fi
  SDK="$(find_sdk || true)"
  if [ -n "$SDK" ]; then
    say "adb      $SDK/platform-tools/adb"
    timeout 15 "$SDK/platform-tools/adb" devices -l 2>/dev/null | tail -n +2 | grep . | sed 's/^/devices  /' || say "devices  none"
  else
    say "adb      not found (ANDROID_HOME=${ANDROID_HOME:-unset})"
  fi
  if [ -f "$STATE" ]; then say "state    $STATE"; sed 's/^/         /' "$STATE"; else say "state    none ($STATE)"; fi
  [ -n "$WARNINGS" ] && { say "warnings:"; printf '%s' "$WARNINGS"; }
  exit 0
fi

# ----------------------------------------------------------------------------- preflight
if [ ! -d "$ROOT/node_modules" ] || [ ! -d "$APP_DIR/node_modules" ]; then
  MAIN="$(git -C "$ROOT" worktree list --porcelain 2>/dev/null | awk '/^worktree /{print $2; exit}')"
  MAIN="$(realpath "${MAIN:-/nonexistent}" 2>/dev/null || printf '/nonexistent')"
  if [ "$MAIN" != "$ROOT" ] && [ -d "$MAIN/node_modules" ]; then
    LOCK=""; for l in bun.lock bun.lockb pnpm-lock.yaml yarn.lock package-lock.json; do [ -f "$ROOT/$l" ] && { LOCK="$l"; break; }; done
    if [ -n "$LOCK" ] && ! cmp -s "$ROOT/$LOCK" "$MAIN/$LOCK"; then
      die 3 "worktree without node_modules and $LOCK differs from the main checkout ($MAIN): run '$PM install' here."
    fi
    LINKED=""
    while IFS= read -r nm; do
      rel="${nm#"$MAIN"/}"; tgt="$ROOT/$rel"
      [ -e "$tgt" ] && continue
      [ -d "$(dirname "$tgt")" ] || continue
      ln -s "$nm" "$tgt" && LINKED="$LINKED $rel"
    done < <(find "$MAIN" -maxdepth 3 -type d -name node_modules -not -path '*/node_modules/*' 2>/dev/null)
    say "preflight: linked node_modules from $MAIN:${LINKED:- (nothing)}"
  else
    die 3 "no node_modules in $ROOT or $APP_DIR: run '$PM install' first."
  fi
fi
if [ "$SERVER" != "none" ] && [ ! -f "$SERVER_DIR/.env" ] && [ -f "$SERVER_DIR/.env.example" ]; then
  MAIN="$(git -C "$ROOT" worktree list --porcelain 2>/dev/null | awk '/^worktree /{print $2; exit}')"
  HINT=""; [ -n "$MAIN" ] && [ "$(realpath "$MAIN")" != "$ROOT" ] && [ -f "$MAIN/${SERVER_DIR#"$ROOT"/}/.env" ] && HINT=" (main checkout has one: ln -s $MAIN/${SERVER_DIR#"$ROOT"/}/.env ${SERVER_DIR#"$ROOT"/}/.env)"
  warn "${SERVER_DIR#"$ROOT"/}/.env missing; the server may fail on its secrets$HINT"
fi

# ----------------------------------------------------------------------------- server
SERVER_PID=""; SERVER_STATUS="skipped"; SERVER_NOTE=""
if [ "$SERVER" != "none" ]; then
  P="$SERVER_PORT_BASE"
  OURS="$(find_ours_port "$P" || true)"
  if [ -n "$OURS" ]; then
    SERVER_PORT="$OURS"; SERVER_PID="$(port_pid "$OURS")"; SERVER_STATUS="reused"
    SERVER_NOTE="pid $SERVER_PID, up $(age_h "$(pid_age "$SERVER_PID")"), cwd $(pid_cwd "$SERVER_PID" | sed "s|^$ROOT/||")"
    HEAD_T="$(git -C "$ROOT" log -1 --format=%ct 2>/dev/null || printf 0)"
    if [ "$(pid_start_epoch "$SERVER_PID")" -lt "$HEAD_T" ]; then
      warn "server on :$SERVER_PORT started before the current HEAD commit ($(git -C "$ROOT" log -1 --format='%h %ci' 2>/dev/null)); hot reload covers app code, not always workspace packages. If behaviour looks stale, ASK THE USER before restarting: kill $SERVER_PID && rerun mobile-up"
    fi
  elif port_listening "$P"; then
    PID="$(port_pid "$P")"; CWD="$( [ -n "$PID" ] && pid_cwd "$PID" || printf '?')"
    ALT="$(free_port_after "$P")" || die 4 "no free port above $P"
    say "server: :$P is held by a foreign process (pid ${PID:-?}, cwd $CWD) → using :$ALT instead"
    SERVER_NOTE="port $P belongs to pid ${PID:-?} (${CWD}); "
    SERVER_PORT="$ALT"
  fi
  if [ -z "$SERVER_PID" ]; then
    if [ -n "$SERVER_CMD" ]; then CMD="$SERVER_CMD"; else CMD="$PM run dev"; fi
    if [ "$SERVER_PORT" != "$SERVER_PORT_BASE" ]; then
      SRC="${SERVER_CMD:-$DEV_SCRIPT}"
      if printf '%s' "$SRC" | grep -qF -- "$SERVER_PORT_BASE"; then
        CMD="$(printf '%s' "$SRC" | sed "s/$SERVER_PORT_BASE/$SERVER_PORT/g")"
      else
        CMD="PORT=$SERVER_PORT $CMD"; warn "dev script has no literal port; started with PORT=$SERVER_PORT, check the log if it still binds :$SERVER_PORT_BASE"
      fi
    fi
    SERVER_PID="$(launch "$SERVER_DIR" "$LOG_SERVER" sh -c "exec $CMD")"
    say "server: starting '$CMD' in ${SERVER_DIR#"$ROOT"/} (pid $SERVER_PID, log $LOG_SERVER)"
    wait_bind "$SERVER_PORT" "$SERVER_TIMEOUT" "$SERVER_PID"; RC=$?
    if [ "$RC" -eq 2 ]; then say "server: process died before binding :$SERVER_PORT"; log_excerpt "$LOG_SERVER"; exit 4
    elif [ "$RC" -eq 1 ]; then say "server: no bind on :$SERVER_PORT after ${SERVER_TIMEOUT}s"; log_excerpt "$LOG_SERVER"; exit 4; fi
    CODE="$(wait_http "http://localhost:$SERVER_PORT/" 60 "$SERVER_PID")"
    if [ "$CODE" = "died" ]; then say "server: process exited right after binding :$SERVER_PORT"; log_excerpt "$LOG_SERVER"; exit 4; fi
    if [ "$CODE" = "000" ]; then say "server: bound :$SERVER_PORT but no HTTP answer in 60s"; log_excerpt "$LOG_SERVER"; exit 4; fi
    LISTENER="$(port_pid "$SERVER_PORT")"; [ -n "$LISTENER" ] && SERVER_PID="$LISTENER"   # the launcher may be a parent (bun run → next)
    SERVER_STATUS="started"; SERVER_NOTE="${SERVER_NOTE}pid $SERVER_PID, GET / → $CODE"
  fi
  say "server: $SERVER_STATUS on :$SERVER_PORT ($SERVER_NOTE)"
fi

# ----------------------------------------------------------------------------- env sync
ENV_STATUS="skipped"; URL=""
if [ "$SERVER" != "none" ] && [ -n "$ENV_VAR" ]; then
  if [ -z "$IP" ]; then
    warn "no LAN IP (no default route?): $ENV_VAR not updated"
  else
    URL="http://$IP:$SERVER_PORT"
    if [ ! -f "$ENV_FILE" ]; then
      if [ -f "$APP_DIR/.env.example" ]; then cp "$APP_DIR/.env.example" "$ENV_FILE"; say "env: created ${ENV_FILE#"$ROOT"/} from .env.example"
      else : > "$ENV_FILE"; say "env: created empty ${ENV_FILE#"$ROOT"/}"; fi
    fi
    CUR="$(grep -E "^${ENV_VAR}=" "$ENV_FILE" | tail -1 | cut -d= -f2- | tr -d '\r' | sed -E 's/^[[:space:]]*"?//; s/"?[[:space:]]*(#.*)?$//')"
    if [ "$CUR" = "$URL" ]; then
      ENV_STATUS="unchanged"
    else
      if grep -qE "^${ENV_VAR}=" "$ENV_FILE"; then
        sed -i -E "s|^${ENV_VAR}=.*|${ENV_VAR}=${URL}|" "$ENV_FILE"
      else
        printf '\n%s=%s\n' "$ENV_VAR" "$URL" >> "$ENV_FILE"
      fi
      NOW="$(grep -E "^${ENV_VAR}=" "$ENV_FILE" | tail -1 | cut -d= -f2- | tr -d '\r')"
      [ "$NOW" = "$URL" ] || die 4 "env: could not write $ENV_VAR=$URL into $ENV_FILE (now: '$NOW')"
      ENV_STATUS="updated (was ${CUR:-<absent>})"
    fi
    say "env: $ENV_VAR=$URL ($ENV_STATUS)"
  fi
fi

# ----------------------------------------------------------------------------- metro
METRO_PID=""; METRO_STATUS="skipped"; METRO_NOTE=""; METRO_URL="$(prev METRO_URL)"; METRO_STALE=""; METRO_LOG_OURS=0
if [ "$TARGET" != "server" ]; then
  P="$METRO_PORT_BASE"; METRO_PORT="$P"
  OURS="$(find_ours_port "$P" || true)"
  if [ -n "$OURS" ]; then
    METRO_PORT="$OURS"; METRO_PID="$(port_pid "$OURS")"; METRO_STATUS="reused"
    METRO_NOTE="pid $METRO_PID, up $(age_h "$(pid_age "$METRO_PID")")"
    METRO_LOG_OURS=1
    [ "$(prev METRO_PID)" != "$METRO_PID" ] && { METRO_URL=""; METRO_LOG_OURS=0; }   # not the Metro we recorded: its env and log are unknown
    if [ -n "$URL" ]; then
      if [ -z "$METRO_URL" ]; then METRO_STALE="Metro on :$METRO_PORT (pid $METRO_PID) was not started by this script, so the $ENV_VAR baked into its bundle is unknown"
      elif [ "$METRO_URL" != "$URL" ]; then METRO_STALE="Metro on :$METRO_PORT was started with $ENV_VAR=$METRO_URL, env now says $URL: the bundle on air is stale"; fi
    fi
  elif port_listening "$P"; then
    PID="$(port_pid "$P")"; CWD="$( [ -n "$PID" ] && pid_cwd "$PID" || printf '?')"
    ALT="$(free_port_after "$P")" || die 5 "no free port above $P"
    say "metro: :$P is held by a foreign process (pid ${PID:-?}, cwd $CWD) → using :$ALT instead"
    METRO_NOTE="port $P belongs to pid ${PID:-?} ($CWD); "
    METRO_PORT="$ALT"
  fi
  if [ -z "$METRO_PID" ]; then
    if [ "$METRO_PORT" != "$METRO_PORT_BASE" ] || [ -z "$APP_DEV_SCRIPT" ]; then
      CMD="expo start --clear --port $METRO_PORT"
    else
      CMD="$PM run dev"
    fi
    METRO_PID="$(launch "$APP_DIR" "$LOG_METRO" sh -c "exec $CMD")"
    say "metro: starting '$CMD' in ${APP_DIR#"$ROOT"/} (pid $METRO_PID, log $LOG_METRO)"
    wait_bind "$METRO_PORT" "$METRO_TIMEOUT" "$METRO_PID"; RC=$?
    if [ "$RC" -eq 2 ]; then say "metro: process died before binding :$METRO_PORT"; log_excerpt "$LOG_METRO"; exit 5
    elif [ "$RC" -eq 1 ]; then say "metro: no bind on :$METRO_PORT after ${METRO_TIMEOUT}s"; log_excerpt "$LOG_METRO"; exit 5; fi
    i=0; while [ "$i" -lt 60 ]; do
      curl -s -m 2 "http://localhost:$METRO_PORT/status" 2>/dev/null | grep -q 'packager-status:running' && break
      i=$((i + 1)); sleep 1
    done
    [ "$i" -ge 60 ] && { say "metro: bound :$METRO_PORT but /status never said running"; log_excerpt "$LOG_METRO"; exit 5; }
    LISTENER="$(port_pid "$METRO_PORT")"; [ -n "$LISTENER" ] && METRO_PID="$LISTENER"
    METRO_STATUS="started"; METRO_NOTE="${METRO_NOTE}pid $METRO_PID, /status running after ${i}s"; METRO_LOG_OURS=1
    METRO_URL="$URL"
  fi
  say "metro: $METRO_STATUS on :$METRO_PORT ($METRO_NOTE)"
  [ -n "$METRO_STALE" ] && warn "$METRO_STALE. Restarting kills a running dev process: ASK THE USER first (kill $METRO_PID && rerun mobile-up)."
fi

# ----------------------------------------------------------------------------- emulator
EMU_STATUS="skipped"; EMU_NOTE=""; SERIAL=""; ADB=""; AVD=""; EXPO_GO_VER=""; BUNDLE_NOTE=""
if [ "$TARGET" = "emulator" ]; then
  SDK="$(find_sdk || true)"
  if [ -z "$SDK" ]; then
    EMU_STATUS="failed"; EMU_NOTE="Android SDK not found (ANDROID_HOME unset, no ~/Android/Sdk, no adb in PATH); set ANDROID_HOME in $MCONF"; EXIT=6
  else
    export ANDROID_HOME="$SDK"
    ADB="$SDK/platform-tools/adb"; EMU="$SDK/emulator/emulator"
    AVDH="$(conf_get "$MCONF" ANDROID_AVD_HOME || true)"
    [ -z "$AVDH" ] && for d in "${ANDROID_AVD_HOME:-}" "${ANDROID_USER_HOME:-}/avd" "$HOME/.android/avd" "$HOME/.config/.android/avd"; do
      [ -n "$d" ] && ls "$d"/*.ini >/dev/null 2>&1 && { AVDH="$d"; break; }
    done
    [ -n "$AVDH" ] && export ANDROID_AVD_HOME="$AVDH"
    adb_() { timeout 20 "$ADB" -s "$SERIAL" "$@"; }
    SERIAL="$(timeout 15 "$ADB" devices 2>/dev/null | grep -oP '^emulator-\d+(?=\s+device$)' | head -1)"
    OTHER="$(timeout 15 "$ADB" devices 2>/dev/null | tail -n +2 | grep -E 'offline|unauthorized' || true)"
    [ -n "$OTHER" ] && warn "adb sees a device that is not ready: $OTHER"
    if [ -n "$SERIAL" ]; then
      EMU_STATUS="reused"; EMU_NOTE="$SERIAL already running"
    elif [ ! -x "$EMU" ]; then
      EMU_STATUS="failed"; EMU_NOTE="no emulator binary at $EMU"; EXIT=6
    else
      AVD="$(conf_get "$MCONF" AVD || true)"
      if [ -z "$AVD" ]; then
        AVDS="$("$EMU" -list-avds 2>/dev/null | grep -v '^INFO' | grep . || true)"
        N=$(printf '%s\n' "$AVDS" | grep -c . || true)
        if [ "$N" -eq 0 ]; then EMU_STATUS="failed"; EMU_NOTE="no AVD found (ANDROID_AVD_HOME=${ANDROID_AVD_HOME:-unset}); create one or set ANDROID_AVD_HOME in $MCONF"; EXIT=6
        elif [ "$N" -gt 1 ]; then EMU_STATUS="failed"; EMU_NOTE="several AVDs ($(printf '%s' "$AVDS" | tr '\n' ' ')): set AVD=<name> in $MCONF (ask the user)"; EXIT=6
        else AVD="$AVDS"; fi
      fi
      if [ -n "$AVD" ]; then
        nohup setsid "$EMU" -avd "$AVD" -no-audio -no-boot-anim > "$LOG_AVD" 2>&1 < /dev/null &
        say "emulator: booting AVD '$AVD' (log $LOG_AVD)"
        i=0
        while [ "$i" -lt "$BOOT_TIMEOUT" ]; do
          SERIAL="$(timeout 15 "$ADB" devices 2>/dev/null | grep -oP '^emulator-\d+(?=\s+device$)' | head -1)"
          [ -n "$SERIAL" ] && [ "$(adb_ shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" = "1" ] && break
          i=$((i + 2)); sleep 2
        done
        if [ -n "$SERIAL" ] && [ "$(adb_ shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" = "1" ]; then
          EMU_STATUS="booted"; EMU_NOTE="$SERIAL (AVD $AVD) in ${i}s"
        else
          EMU_STATUS="failed"; EMU_NOTE="AVD '$AVD' did not finish booting in ${BOOT_TIMEOUT}s (see $LOG_AVD)"; EXIT=6; SERIAL=""
        fi
      fi
    fi
    if [ -n "$SERIAL" ]; then
      if ! adb_ shell pm path host.exp.exponent 2>/dev/null | grep -q package; then
        SDKV="$(grep -oP '"expo"\s*:\s*"[~^]?\K[0-9]+' "$APP_DIR/package.json" | head -1)"
        EMU_STATUS="failed"; EMU_NOTE="$EMU_NOTE; Expo Go is not installed on $SERIAL. Install: npx expo-go download android ${SDKV:-<sdk>} && $ADB -s $SERIAL install -r <apk>"; EXIT=6
      else
        EXPO_GO_VER="$(adb_ shell dumpsys package host.exp.exponent 2>/dev/null | grep -m1 versionName | cut -d= -f2 | tr -d '\r ')"
        SDKV="$(grep -oP '"expo"\s*:\s*"[~^]?\K[0-9]+' "$APP_DIR/package.json" | head -1)"
        if [ -n "$SDKV" ]; then
          expo_go_compatible "$EXPO_GO_VER" "$SDKV"
          [ $? -eq 1 ] && warn "Expo Go $EXPO_GO_VER on $SERIAL vs project SDK $SDKV: expect 'Project is incompatible with this version of Expo Go'. Fix: npx expo-go download android $SDKV && $ADB -s $SERIAL install -r <apk>"
        fi
        # the emulator is one shared device: another session may be driving Expo Go right now
        # 10.0.2.2 is Android's alias for the host machine, immune to VPN/firewall on the LAN IP
        DL="exp://10.0.2.2:$METRO_PORT"
        CUR_LINE="$(adb_ logcat -d -s ReactNativeJS:I 2>/dev/null | grep -a 'Running "main"' | tail -1)"
        CUR_URI="$(printf '%s' "$CUR_LINE" | grep -oP '"initialUri":"\K[^"]*')"
        CUR_HOST="$(printf '%s' "$CUR_URI" | sed -E 's|^exp://([^/]+).*|\1|')"
        FOCUS="$(adb_ shell dumpsys window 2>/dev/null | grep -m1 mCurrentFocus)"
        BUSY=0
        if [ "$TAKE_EMULATOR" -eq 0 ] && [ -n "$CUR_HOST" ] && [ "$CUR_HOST" != "10.0.2.2:$METRO_PORT" ] && printf '%s' "$FOCUS" | grep -q 'host.exp.exponent/.*ExperienceActivity'; then
          BUSY=1
          EMU_STATUS="busy"; EMU_NOTE="$EMU_NOTE; Expo Go is showing $CUR_URI (launched $(printf '%s' "$CUR_LINE" | cut -c1-18)), another Metro than ours ($DL). Another session may be driving this emulator: ASK THE USER, then rerun with --take-emulator"; EXIT=6
        fi
        # open the app with a fresh bundle: force-stop, pause, deep link, then wait for Metro to say Bundled
        BEFORE=0; [ -f "$LOG_METRO" ] && BEFORE=$(wc -l < "$LOG_METRO")
        OUT=""
        if [ "$BUSY" -eq 0 ]; then
          adb_ shell am force-stop host.exp.exponent >/dev/null 2>&1
          sleep 3
          OUT="$(adb_ shell am start -a android.intent.action.VIEW -d "$DL" host.exp.exponent 2>&1)"
        fi
        if [ "$BUSY" -eq 1 ]; then
          :
        elif printf '%s' "$OUT" | grep -qiE 'error|exception'; then
          EMU_STATUS="failed"; EMU_NOTE="$EMU_NOTE; am start failed: $(printf '%s' "$OUT" | tr '\n' ' ' | cut -c1-200)"; EXIT=6
        else
          if [ "$METRO_LOG_OURS" -eq 0 ]; then
            BUNDLE_NOTE="bundle delivery unknown (Metro log is not ours)"
          else
            i=0
            while [ "$i" -lt 120 ]; do
              tail -n +"$((BEFORE + 1))" "$LOG_METRO" 2>/dev/null | tr -d '\000' | grep -q 'Bundled' && break
              i=$((i + 1)); sleep 1
            done
            if [ "$i" -lt 120 ]; then BUNDLE_NOTE="bundle delivered after ${i}s ($(tail -n +"$((BEFORE + 1))" "$LOG_METRO" | tr -d '\000' | grep -m1 'Bundled' | sed 's/^[[:space:]]*//' | cut -c1-80))"
            else BUNDLE_NOTE="no 'Bundled' line in $LOG_METRO within 120s: check the emulator screen and the log"; EXIT=6; fi
          fi
          EMU_NOTE="$EMU_NOTE; opened $DL"
        fi
      fi
    fi
  fi
  say "emulator: $EMU_STATUS ($EMU_NOTE)${BUNDLE_NOTE:+; $BUNDLE_NOTE}"
fi

# ----------------------------------------------------------------------------- state (fields this run did not touch keep the previous value)
[ "$TARGET" = "server" ] && { METRO_PORT="$(prev METRO_PORT)"; METRO_PID="$(prev METRO_PID)"; }
[ -z "$ADB" ] && ADB="$(prev ADB)"; [ -z "$SERIAL" ] && SERIAL="$(prev SERIAL)"; [ -z "$AVD" ] && AVD="$(prev AVD)"; [ -z "$EXPO_GO_VER" ] && EXPO_GO_VER="$(prev EXPO_GO)"
{
  printf 'TARGET=%s\nTIME=%s\nROOT=%s\nIP=%s\n' "$TARGET" "$(date '+%F %T')" "$ROOT" "$IP"
  printf 'SERVER_PORT=%s\nSERVER_PID=%s\nMETRO_PORT=%s\nMETRO_PID=%s\nMETRO_URL=%s\n' "${SERVER_PORT:-}" "$SERVER_PID" "${METRO_PORT:-}" "$METRO_PID" "$METRO_URL"
  printf 'ENV_FILE=%s\nENV_VAR=%s\nURL=%s\n' "$ENV_FILE" "$ENV_VAR" "$URL"
  printf 'ADB=%s\nSERIAL=%s\nAVD=%s\nEXPO_GO=%s\n' "$ADB" "$SERIAL" "$AVD" "$EXPO_GO_VER"
  printf 'LOG_SERVER=%s\nLOG_METRO=%s\nLOG_AVD=%s\n' "$LOG_SERVER" "$LOG_METRO" "$LOG_AVD"
} > "$STATE"

# ----------------------------------------------------------------------------- summary
say ""
say "== mobile-up: $TARGET ($SLUG) =="
if [ "$SERVER" != "none" ]; then
  say "server    $SERVER_STATUS :$SERVER_PORT   http://localhost:$SERVER_PORT${IP:+   http://$IP:$SERVER_PORT}"
  [ -n "$ENV_VAR" ] && say "env       $ENV_VAR=${URL:-?} ($ENV_STATUS)"
fi
if [ "$TARGET" != "server" ]; then
  say "metro     $METRO_STATUS :$METRO_PORT   exp://${IP:-?}:$METRO_PORT"
fi
if [ "$TARGET" = "emulator" ]; then
  say "emulator  $EMU_STATUS${SERIAL:+   $SERIAL}${EXPO_GO_VER:+   Expo Go $EXPO_GO_VER}"
  [ -n "$BUNDLE_NOTE" ] && say "bundle    $BUNDLE_NOTE"
  [ -n "$ADB" ] && say "adb       $ADB${SERIAL:+ -s $SERIAL}"
fi
say "logs      $LOG_SERVER"; say "          $LOG_METRO"; [ "$TARGET" = "emulator" ] && say "          $LOG_AVD"
say "state     $STATE"
if [ "$TARGET" = "app" ]; then
  say ""
  if have qrencode; then qrencode -t ANSIUTF8 "exp://${IP:-?}:$METRO_PORT"; else say "(install qrencode for a QR here, or type exp://${IP:-?}:$METRO_PORT in Expo Go)"; fi
  if [ -n "$IP_NET" ]; then
    if systemctl is-active ufw >/dev/null 2>&1; then
      say ""; say "ufw is active. If the phone cannot connect, allow this network (needs sudo, ask the user):"
      say "  sudo ufw allow from $IP_NET to any port $METRO_PORT proto tcp"
      [ "$SERVER" != "none" ] && say "  sudo ufw allow from $IP_NET to any port $SERVER_PORT proto tcp"
      say "  (rules are per network: a different Wi-Fi needs them again)"
    elif systemctl is-active firewalld >/dev/null 2>&1; then
      say ""; say "firewalld is active. If the phone cannot connect (needs sudo, ask the user):"
      if [ "$SERVER" != "none" ]; then say "  sudo firewall-cmd --add-port=$METRO_PORT/tcp --add-port=$SERVER_PORT/tcp"
      else say "  sudo firewall-cmd --add-port=$METRO_PORT/tcp"; fi
    fi
  fi
fi
[ -n "$WARNINGS" ] && { say ""; say "warnings:"; printf '%s' "$WARNINGS"; }
exit "$EXIT"
