#!/usr/bin/env bash
# Runs scripts/dev-up.sh against real python http.servers in throwaway git repos.
# Usage: bash evals/dev-up-script.test.sh   (Linux: python3, git, ss, curl, setsid; docker for bash 3.2)
set -uo pipefail
HERE=$(cd "$(dirname "$0")/.." && pwd)
DU="$HERE/scripts/dev-up.sh"
T=$(mktemp -d); T=$(cd "$T" && pwd -P)
export DEV_UP_CACHE="$T/cache" CLAUDE_CODE_SESSION_ID=session-a
P=$((20000 + RANDOM % 20000)); P2=$((P + 1)); P3=$((P + 2))
fails=0
check() { if [[ "$2" == $3 ]]; then echo "ok   $1"; else echo "FAIL $1: got '$2', want '$3'"; fails=$((fails + 1)); fi; }
cleanup() {
  for p in $P $P2 $P3; do pkill -f "http.server $p" 2>/dev/null; done
  [ -n "${WATCH:-}" ] && kill -- -"$WATCH" 2>/dev/null
  rm -rf "$T"
}
trap cleanup EXIT
git init -q "$T/app" && cd "$T/app" && git commit -q --allow-empty -m init || exit 1

check "owner on a free port" "$("$DU" owner $P)" "FREE"
"$DU" state $P init >/dev/null
"$DU" serve $P -- "python3 -m http.server $P" 2>/dev/null & SERVE=$!
check "wait on a healthy server" "$("$DU" wait $P | head -1)" "READY http=200"
check "owner names the listener pid and who started it" "$("$DU" owner $P)" "BUSY pid=$(pgrep -f "http.server $P" | head -1) cwd=$T/app mine=yes via=dev-up state=mine"
"$DU" state $P set server_task=b123 tab_id=77
check "init keeps this session's state" "$("$DU" state $P init | head -1)" "kept:*"
check "init kept the fields" "$("$DU" state $P get server_task),$("$DU" state $P get tab_id)" "b123,77"
check "owner from another session says state=other" "$(CLAUDE_CODE_SESSION_ID=session-b "$DU" owner $P)" "*state=other"
check "serve refuses a bound port" "$("$DU" serve $P -- true 2>&1; echo "exit=$?")" "*exit=3"
check "state refuses a placeholder task id" "$("$DU" state $P set watcher_task=PENDING 2>&1; echo "exit=$?")" "*exit=3"

"$DU" state $P exclude 'type is invalid (expected' >/dev/null
setsid "$DU" watch $P >"$T/events" & WATCH=$!
sleep 1
check "unwatched is silent while the watcher lives" "$("$DU" unwatched)" ""
{
  echo ' GET /login?error=access_denied 200 in 12ms'
  echo '127.0.0.1 - - "GET /favicon.ico HTTP/1.1" 404 -'
  echo 'Error: NEXT_REDIRECT'
  echo 'npm error signal SIGTERM'
  echo 'Error: type is invalid (expected a string)'
  echo 'TypeError: boom'
} >>"$DEV_UP_CACHE/$P.log"
sleep 1
check "watch passes only the real error, excludes are literal" "$(cat "$T/events")" "TypeError: boom"
kill -- -"$WATCH"; WATCH=""; sleep 0.5
check "unwatched flags a dead watcher" "$("$DU" unwatched)" "*port $P has no live watcher*"
check "unwatched ignores another session" "$(CLAUDE_CODE_SESSION_ID=session-b "$DU" unwatched)" ""
"$DU" state $P pause >/dev/null
check "unwatched stays quiet while paused" "$("$DU" unwatched)" ""

(cd "$T" && exec python3 -m http.server $P2 >/dev/null 2>&1) &
for _ in $(seq 20); do ss -ltnH "sport = :$P2" | grep -q . && break; sleep 0.25; done
check "stop refuses a listener serve did not start" "$("$DU" stop $P2 2>&1; echo "exit=$?")" "*exit=3"
check "serve refuses and wait reports it" "$("$DU" serve $P2 -- true 2>/dev/null; "$DU" wait $P2 | tr '\n' ' ')" "DIED*port $P2 is already bound*"
check "stop --force frees a foreign listener" "$("$DU" stop $P2 --force)" "STOPPED"

check "stop frees the server serve started" "$("$DU" stop $P)" "STOPPED"
for _ in $(seq 20); do kill -0 "$SERVE" 2>/dev/null || break; sleep 0.25; done
check "serve exits when its server dies" "$(kill -0 "$SERVE" 2>/dev/null && echo alive || echo gone)" "gone"
check "unwatched reports a dead server once" "$("$DU" unwatched)" "*server on port $P is down*"
check "and then clears its state" "$("$DU" unwatched)" ""

"$DU" serve $P -- "echo starting; sleep 1; exit 1" 2>/dev/null &
check "wait reports a death the log never names" "$("$DU" wait $P | head -1)" "DIED"
"$DU" serve $P -- "echo '[0] tailwind exited with code 1'; sleep 1; exec python3 -m http.server $P" 2>/dev/null &
check "wait ignores scary text from a live server" "$("$DU" wait $P | head -1)" "READY http=200"
"$DU" stop $P >/dev/null

"$DU" serve $P -- "sleep 2; exec python3 -m http.server $P" 2>/dev/null &
sleep 0.5
check "stop catches a server that has not bound yet" "$("$DU" stop $P)" "STOPPED"
sleep 2.5
check "and it never binds later" "$("$DU" owner $P)" "FREE"

setsid "$DU" watch $P >/dev/null 2>&1 & W2=$!
sleep 1; kill -TERM "$W2"; sleep 0.5
check "a stopped watcher leaves no tail behind" "$(pgrep -f "tail -n 0 -F $DEV_UP_CACHE/$P.log" | wc -l)" "0"

git -C "$T/app" worktree add -q .claude/worktrees/wt 2>/dev/null
"$DU" serve $P3 --dir "$T/app/.claude/worktrees/wt" -- "python3 -m http.server $P3" 2>/dev/null &
"$DU" wait $P3 >/dev/null
check "a nested worktree is not this checkout" "$("$DU" owner $P3)" "*mine=worktree*"
"$DU" stop $P3 >/dev/null

printf '%s\n' 'DATABASE_URL=postgresql://u:hunter2@localhost:54322/db' 'export NEXTAUTH_URL=http://localhost:3001' 'NEXT_PUBLIC_SUPABASE_URL=http://127.0.0.1:54321' >"$T/app/.env"
out=$("$DU" preflight "$T/app")
check "preflight warns about the app origin" "$out" "*NEXTAUTH_URL expects port 3001*"
check "preflight leaves local services alone" "$(printf '%s' "$out" | grep -c SUPABASE)" "0"
check "preflight never prints a secret or a database url" "$(printf '%s' "$out" | grep -cE 'hunter2|DATABASE_URL')" "0"

export HOME="$T/home"; unset DEV_UP_CACHE CLAUDE_CODE_SESSION_ID
mkdir -p "$HOME"
CLAUDE_CODE_SESSION_ID=session-h "$DU" state $P init >/dev/null
hook=$(sed -n "s/^ *command: '\(.*\)'$/\1/p" "$HERE/SKILL.md")
check "the hook reaches the script through the cache pointer" "$(printf '{"session_id":"session-h"}' | bash -c "$hook")" "*server on port $P is down*"
check "the hook is silent for other sessions" "$(printf '{"session_id":"session-x"}' | bash -c "$hook")" ""

if command -v docker >/dev/null && docker image inspect bash:3.2 >/dev/null 2>&1; then
  out=$(docker run --rm -v "$HERE/scripts:/s:ro" -e CLAUDE_CODE_SESSION_ID=s bash:3.2 bash -c \
    'export DEV_UP_CACHE=/tmp/c; bash /s/dev-up.sh state 3000 init >/dev/null && bash /s/dev-up.sh state 3000 set tab_id=77 server_task=b1 && bash /s/dev-up.sh state 3000 exclude "some (text" >/dev/null && bash /s/dev-up.sh state 3000 get tab_id' 2>&1)
  check "state works on bash 3.2" "$out" "77"
else
  echo "skip bash 3.2 (no docker image bash:3.2)"
fi

echo "$fails failure(s)"
exit $((fails > 0))
