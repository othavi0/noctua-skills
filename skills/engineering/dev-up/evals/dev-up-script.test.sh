#!/usr/bin/env bash
# Runs scripts/dev-up.sh against a real python http.server in a throwaway git repo.
# Usage: bash evals/dev-up-script.test.sh   (needs python3, git, ss or lsof, curl, fuser)
set -uo pipefail
HERE=$(cd "$(dirname "$0")/.." && pwd)
DU="$HERE/scripts/dev-up.sh"
T=$(mktemp -d); export DEV_UP_CACHE="$T/cache"
PORT=$((20000 + RANDOM % 20000))
fails=0
check() { if [ "$2" = "$3" ] || [[ "$2" == $3 ]]; then echo "ok   $1"; else echo "FAIL $1: got '$2', want '$3'"; fails=$((fails + 1)); fi; }
cleanup() { fuser -k "$PORT/tcp" >/dev/null 2>&1; [ -n "${WATCH:-}" ] && kill -- -"$WATCH" 2>/dev/null; rm -rf "$T"; }
trap cleanup EXIT

git init -q "$T/app" && cd "$T/app" || exit 1

check "owner on a free port" "$("$DU" owner $PORT)" "FREE"

"$DU" serve $PORT -- "python3 -m http.server $PORT" & SERVE=$!
check "wait on a healthy server" "$("$DU" wait $PORT | head -1)" "READY http=200"
check "owner reports the listener's pid, not its fd" "$("$DU" owner $PORT)" "BUSY pid=$(pgrep -f "http.server $PORT" | head -1) cwd=$T/app mine=yes"
check "serve refuses a bound port" "$("$DU" serve $PORT -- true 2>&1; echo "exit=$?")" "*exit=3"

"$DU" state $PORT init owner=self
check "state refuses a placeholder task id" "$("$DU" state $PORT set watcher_task=PENDING 2>&1; echo "exit=$?")" "*exit=3"
"$DU" state $PORT set server_task=b123 watcher_task=w456 tab_id=77
check "state keeps every field" "$("$DU" state $PORT get tab_id),$("$DU" state $PORT get owner)" "77,self"
check "unwatched is silent while the watcher lives" "$("$DU" unwatched)" ""
"$DU" state $PORT set watcher_task=
check "unwatched flags an expired watcher" "$("$DU" unwatched)" "*port $PORT has no live watcher*"
check "unwatched ignores another checkout" "$(cd "$T" && "$DU" unwatched)" ""

"$DU" state $PORT exclude 'DeprecationWarning'
setsid "$DU" watch $PORT >"$T/events" & WATCH=$!
sleep 1
LOG="$DEV_UP_CACHE/$PORT.log"
{
  echo ' GET /login?error=access_denied 200 in 12ms'
  echo '127.0.0.1 - - "GET /favicon.ico HTTP/1.1" 404 -'
  echo 'Error: NEXT_REDIRECT'
  echo 'DeprecationWarning: Error in old api'
  echo 'TypeError: boom'
} >>"$LOG"
sleep 1
check "watch passes only the real error" "$(cat "$T/events")" "TypeError: boom"

check "stop frees the port the session owns" "$("$DU" stop $PORT)" "STOPPED"
wait "$SERVE" 2>/dev/null
check "serve exits when the server dies" "$(kill -0 "$SERVE" 2>/dev/null && echo alive || echo gone)" "gone"
"$DU" state $PORT set owner=reused
check "stop refuses a reused server" "$("$DU" stop $PORT 2>&1; echo "exit=$?")" "*exit=3"
check "unwatched flags a dead server" "$("$DU" unwatched)" "*port $PORT is down*"

"$DU" serve $PORT -- "python3 -c 'import not_a_module'" &
check "wait reports a crash on boot" "$("$DU" wait $PORT | head -1)" "DIED"

echo "$fails failure(s)"
exit $((fails > 0))
