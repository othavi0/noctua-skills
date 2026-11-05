#!/usr/bin/env bash
# Runs scripts/dev-up.sh against real python http.servers in throwaway git repos, and drives one
# of them through agent-browser when it is on PATH.
# Usage: bash evals/dev-up-script.test.sh   (Linux with a systemd user manager: python3, git, ss, curl,
# setsid, timeout; docker for bash 3.2)
set -uo pipefail
HERE=$(cd "$(dirname "$0")/.." && pwd)
DU="$HERE/scripts/dev-up.sh"
T=$(mktemp -d); T=$(cd "$T" && pwd -P)
export DEV_UP_CACHE="$T/cache" CLAUDE_CODE_SESSION_ID=session-a
P=$((20000 + RANDOM % 20000)); P2=$((P + 1)); P3=$((P + 2))
fails=0
check() { if [[ "$2" == $3 ]]; then echo "ok   $1"; else echo "FAIL $1: got '$2', want '$3'"; fails=$((fails + 1)); fi; }
serve() { timeout 10 "$DU" serve "$@"; }
active() { systemctl --user is-active "dev-up-$1" 2>/dev/null; }
cleanup() {
  for p in $P $P2 $P3; do
    systemctl --user stop "dev-up-$p" 2>/dev/null; systemctl --user reset-failed "dev-up-$p" 2>/dev/null
    pkill -f "http.server $p" 2>/dev/null
  done
  [ -n "${WATCH:-}" ] && kill -- -"$WATCH" 2>/dev/null
  command -v agent-browser >/dev/null && agent-browser --session "devup-$P" close >/dev/null 2>&1
  rm -rf "$T"
}
trap cleanup EXIT
git init -q "$T/app" && cd "$T/app" && git commit -q --allow-empty -m init || exit 1
mkdir -p "$T/bin" "$T/app/node_modules/.bin"
printf '#!/bin/sh\necho caller-path-ok\n' >"$T/bin/only-on-caller-path"
printf '#!/bin/sh\necho local-bin-ok\n' >"$T/app/node_modules/.bin/only-in-node-modules"
chmod +x "$T/bin/only-on-caller-path" "$T/app/node_modules/.bin/only-in-node-modules"

check "owner on a free port" "$("$DU" owner $P)" "FREE"
"$DU" state $P init >/dev/null
# shellcheck disable=SC2016 # $DEV_UP_PROBE must expand inside the unit, not here
out=$(PATH="$T/bin:$PATH" DEV_UP_PROBE=probe-xyz serve $P -- 'only-on-caller-path; only-in-node-modules; echo "probe=$DEV_UP_PROBE"; exec python3 -m http.server '$P 2>&1)
check "serve returns once the unit runs" "$(printf '%s' "$out" | head -1)" "STARTED unit=dev-up-$P *"
check "the server runs as a systemd user unit" "$(active $P)" "active"
check "wait on a healthy server" "$("$DU" wait $P | head -1)" "READY http=200"
check "the unit gets the caller's PATH, env and node_modules/.bin" "$(grep -E 'ok$|^probe=' "$DEV_UP_CACHE/$P.log" | tr '\n' ' ')" "caller-path-ok local-bin-ok probe=probe-xyz "
check "owner names the listener pid and who started it" "$("$DU" owner $P)" "BUSY pid=$(pgrep -f "http.server $P" | head -1) cwd=$T/app mine=yes via=dev-up state=mine"
check "owner exits 0 when this checkout serves the port" "$("$DU" owner $P >/dev/null; echo "exit=$?")" "exit=0"
check "preflight names the port this directory already serves" "$("$DU" preflight "$T/app")" "*warn served: this directory already serves port $P (pid *)*"
# No headless shell, no env browser: the session falls back to agent-browser's own Chrome.
check "browser works with no browser configured" "$(HOME="$T/nobrowser" PLAYWRIGHT_BROWSERS_PATH= AGENT_BROWSER_EXECUTABLE_PATH= DEV_UP_AB_HEADLESS= "$DU" browser $P2 2>&1)" "mode=headless session=devup-$P2 exe= profile=*"

if command -v agent-browser >/dev/null; then
  export DEV_UP_AB_STATE="$T/abstate"
  printf '<title>eval-page</title><button id=b onclick="this.textContent=%s">x</button>\n' "'clicked'" >"$T/app/index.html"
  ab() { timeout 60 "$DU" ab $P "$@" 2>/dev/null; }
  bpid() { pgrep -of "[u]ser-data-dir=$T/abstate/profiles/$P-headless"; }
  ab open "http://localhost:$P/" >/dev/null
  check "ab opens the app in the port's session" "$(ab get title)" "eval-page"
  pid1=$(bpid)
  ab click '#b' >/dev/null
  check "ab drives the page" "$(ab get text '#b')" "clicked"
  ab set viewport 390 844 >/dev/null
  check "ab emulates the viewport" "$(ab eval 'window.innerWidth')" "390"
  check "every ab call reuses the browser open started" "$(bpid)" "$pid1"
  check "browser names the session, the mode and a live browser" "$("$DU" browser $P)" "mode=headless session=devup-$P *alive=yes"
  check "hide on a live headless session changes nothing" "$("$DU" hide $P)" "ALREADY mode=headless"
  check "state show reports the browser" "$("$DU" state $P show | tail -1)" "browser_alive=yes mode=headless session=devup-$P"
  ab close >/dev/null
  check "ab close ends the session" "$("$DU" browser $P)" "*alive=no"
  check "a command on a closed session reopens it on the app" "$(ab get title)" "eval-page"
  export DEV_UP_AB_NOWINDOW=1
  "$DU" show $P >/dev/null
  ab eval "document.cookie='sid=logado; path=/; max-age=3600'" >/dev/null
  ab close >/dev/null
  "$DU" hide $P >/dev/null
  check "hide after the window closed keeps the login" "$(ab eval 'document.cookie')" "*sid=logado*"
  unset DEV_UP_AB_NOWINDOW
  ab close >/dev/null
  rm -f "$T/app/index.html"
else
  echo "skip agent-browser checks (agent-browser is not on PATH)"
fi
check "state show sees the unit" "$("$DU" state $P show | grep -o 'server_alive=[a-z]*')" "server_alive=yes"
"$DU" state $P set watcher_task=b123 ab_mode=headed
check "init keeps this session's state" "$("$DU" state $P init | head -1)" "kept:*"
check "init kept the fields" "$("$DU" state $P get watcher_task),$("$DU" state $P get ab_mode)" "b123,headed"
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
{
  echo 'Error: type is invalid (expected a number)'
  echo 'ReferenceError: late is not defined'
} >>"$DEV_UP_CACHE/$P.log"
out=$("$DU" unwatched)
check "unwatched prints the errors logged since the last prompt" "$out" "dev-up: port $P logged errors since the last prompt:*TypeError: boom*ReferenceError: late is not defined"
check "unwatched never asks for a re-arm" "$(printf '%s' "$out" | grep -ciE 're-arm|no live watcher')" "0"
check "unwatched applies the excludes" "$(printf '%s' "$out" | grep -c 'type is invalid')" "0"
check "unwatched prints each error once" "$("$DU" unwatched)" ""
check "unwatched ignores another session" "$(CLAUDE_CODE_SESSION_ID=session-b "$DU" unwatched)" ""
"$DU" state $P pause >/dev/null
echo 'TypeError: during an edit round' >>"$DEV_UP_CACHE/$P.log"
check "unwatched stays quiet while paused" "$("$DU" unwatched)" ""

mkdir "$T/gone"
(cd "$T/gone" && exec python3 -m http.server $P2 >/dev/null 2>&1) & ORPHAN=$!
for _ in $(seq 20); do ss -ltnH "sport = :$P2" | grep -q . && break; sleep 0.25; done
rm -rf "$T/gone"
check "owner flags a server whose worktree was deleted" "$("$DU" owner $P2)" "BUSY pid=$ORPHAN cwd=$T/gone (deleted) mine=orphan *"
check "stop takes an orphan down without --force" "$("$DU" stop $P2)" "STOPPED orphan pid=$ORPHAN cwd=$T/gone (deleted)"
check "and frees its port" "$("$DU" owner $P2)" "FREE"

(cd "$T" && exec python3 -m http.server $P2 >/dev/null 2>&1) &
for _ in $(seq 20); do ss -ltnH "sport = :$P2" | grep -q . && break; sleep 0.25; done
check "stop refuses a listener serve did not start" "$("$DU" stop $P2 2>&1; echo "exit=$?")" "*exit=3"
check "serve refuses and wait reports it" "$("$DU" serve $P2 -- true 2>/dev/null; "$DU" wait $P2 | tr '\n' ' ')" "DIED*port $P2 is already bound*"
check "stop --force frees a foreign listener" "$("$DU" stop $P2 --force)" "STOPPED"

mkdir "$T/live (deleted)"
(cd "$T/live (deleted)" && exec python3 -m http.server $P2 >/dev/null 2>&1) &
for _ in $(seq 20); do ss -ltnH "sport = :$P2" | grep -q . && break; sleep 0.25; done
check "a live dir named '* (deleted)' is not an orphan" "$("$DU" owner $P2)" "*mine=no*"
check "owner exits 1 for a foreign listener" "$("$DU" owner $P2 >/dev/null; echo "exit=$?")" "exit=1"
check "and stop still asks before killing it" "$("$DU" stop $P2 2>&1; echo "exit=$?")" "*exit=3"
"$DU" stop $P2 --force >/dev/null

setsid "$DU" watch $P >"$T/events" & WATCH=$!
sleep 1
systemctl --user stop "dev-up-$P" 2>/dev/null
for _ in $(seq 30); do grep -q 'SERVER DOWN' "$T/events" && break; sleep 0.25; done
check "watch reports SERVER DOWN when the unit stops" "$(cat "$T/events")" "*dev-up: SERVER DOWN on port $P*"
serve $P -- "python3 -m http.server $P" >/dev/null 2>&1
"$DU" wait $P >/dev/null
sleep 2 # the probe polls each second for the server coming back; a real server stays up longer
systemctl --user stop "dev-up-$P" 2>/dev/null
for _ in $(seq 40); do [ "$(grep -c 'SERVER DOWN' "$T/events")" -ge 2 ] && break; sleep 0.25; done
check "the same watcher reports a second fall after a restart" "$(grep -c 'SERVER DOWN' "$T/events")" "2"
kill -- -"$WATCH"; WATCH=""
serve $P -- "python3 -m http.server $P" >/dev/null 2>&1
"$DU" wait $P >/dev/null
check "stop frees the server serve started" "$("$DU" stop $P)" "STOPPED"
check "stop removes the unit" "$(active $P)" "inactive"
: >"$DEV_UP_CACHE/$P.pid"
check "unwatched reports a dead server once" "$("$DU" unwatched)" "*server on port $P is down*"
check "and then clears its state" "$("$DU" unwatched)" ""
check "the server-down branch removes the hook offset and the legacy pid file" "$(ls "$DEV_UP_CACHE/$P.hookoff" "$DEV_UP_CACHE/$P.state" "$DEV_UP_CACHE/$P.pid" 2>/dev/null)" ""

systemd-run --user --quiet --unit="dev-up-$P" false
for _ in $(seq 20); do [ "$(active $P)" = failed ] && break; sleep 0.25; done
check "serve replaces a failed leftover unit" "$(serve $P -- "exec python3 -m http.server $P" 2>&1)" "STARTED unit=dev-up-$P *"
"$DU" wait $P >/dev/null; "$DU" stop $P >/dev/null; systemctl --user reset-failed "dev-up-$P" 2>/dev/null

"$DU" state $P init >/dev/null
printf 'DEV_UP_ENVPORT=%s\n' "$P" >"$T/app/.env"
# shellcheck disable=SC2016 # the unit's bash expands these, not this shell and not systemd
serve $P -- 'X=v; echo "x=${X} pid=$$"; set -a; . ./.env; set +a; exec python3 -m http.server ${DEV_UP_ENVPORT}' >/dev/null 2>&1
check "the port read from .env reaches the server" "$("$DU" wait $P | head -1)" "READY http=200"
check "bash, not systemd, expands \${VAR} and \$\$" "$(grep '^x=' "$DEV_UP_CACHE/$P.log")" "x=v pid=[0-9]*"
"$DU" stop $P >/dev/null

echo 30 >"$DEV_UP_CACHE/$P.hookoff"
serve $P -- "echo 'ReferenceError: x is not defined at boot'; exec python3 -m http.server $P" >/dev/null 2>&1
"$DU" wait $P >/dev/null
check "after a restart the hook reads the new log from its start" "$("$DU" unwatched)" "*ReferenceError: x is not defined at boot*"
mv "$DEV_UP_CACHE/$P.log" "$T/log.bak"
check "the hook writes nothing to stderr when the log is gone" "$("$DU" unwatched 2>&1 >/dev/null)" ""
mv "$T/log.bak" "$DEV_UP_CACHE/$P.log"
"$DU" stop $P >/dev/null

serve $P -- "trap '' TERM; exec python3 -m http.server $P" >/dev/null 2>&1
"$DU" wait $P >/dev/null
t0=$(date +%s); out=$("$DU" stop $P); t1=$(date +%s)
check "stop kills a server that ignores SIGTERM within 15 s" "$out $((t1 - t0 <= 15))" "STOPPED 1"
"$DU" state $P rm

serve $P -- "echo starting; sleep 1; exit 1" >/dev/null 2>&1
check "wait reports a death the log never names" "$("$DU" wait $P | head -1)" "DIED"
serve $P -- "echo '[0] tailwind exited with code 1'; sleep 1; exec python3 -m http.server $P" >/dev/null 2>&1
check "wait ignores scary text from a live server" "$("$DU" wait $P | head -1)" "READY http=200"
"$DU" stop $P >/dev/null

serve $P -- "sleep 2; exec python3 -m http.server $P" >/dev/null 2>&1
sleep 0.5
check "stop catches a server that has not bound yet" "$("$DU" stop $P)" "STOPPED"
sleep 2.5
check "and it never binds later" "$("$DU" owner $P)" "FREE"

setsid "$DU" watch $P >/dev/null 2>&1 & W2=$!
sleep 1; kill -TERM "$W2"; sleep 0.5
check "a stopped watcher leaves no tail behind" "$(pgrep -f "tail -n 0 -F $DEV_UP_CACHE/$P.log" | wc -l)" "0"

git -C "$T/app" worktree add -q .claude/worktrees/wt 2>/dev/null
serve $P3 --dir "$T/app/.claude/worktrees/wt" --mem 64M -- "python3 -m http.server $P3" >/dev/null 2>&1
"$DU" wait $P3 >/dev/null
check "a nested worktree is not this checkout" "$("$DU" owner $P3)" "*mine=worktree*"
check "--mem becomes the unit's MemoryMax" "$(systemctl --user show -p MemoryMax --value "dev-up-$P3")" "67108864"
"$DU" state $P3 init >/dev/null; : >"$DEV_UP_CACHE/$P3.hookoff"; : >"$DEV_UP_CACHE/$P3.pid"
"$DU" stop $P3 >/dev/null
"$DU" state $P3 rm
check "state rm removes the hook offset and the legacy pid file" "$(ls "$DEV_UP_CACHE/$P3.hookoff" "$DEV_UP_CACHE/$P3.pid" 2>/dev/null)" ""

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
check "help prints the whole header" "$("$DU" help | tail -1)" "# Exit codes: *"
check "an unknown command lists every command" "$("$DU" bogus | grep -c 'unwatched')" "1"

if command -v docker >/dev/null && docker image inspect bash:3.2 >/dev/null 2>&1; then
  out=$(docker run --rm -v "$HERE/scripts:/s:ro" -e CLAUDE_CODE_SESSION_ID=s bash:3.2 bash -c \
    'export DEV_UP_CACHE=/tmp/c; bash /s/dev-up.sh state 3000 init >/dev/null && bash /s/dev-up.sh state 3000 set ab_mode=headed watcher_task=b1 && bash /s/dev-up.sh state 3000 exclude "some (text" >/dev/null && bash /s/dev-up.sh state 3000 get ab_mode' 2>&1)
  check "state works on bash 3.2" "$out" "headed"
else
  echo "skip bash 3.2 (no docker image bash:3.2)"
fi

echo "$fails failure(s)"
exit $((fails > 0))
