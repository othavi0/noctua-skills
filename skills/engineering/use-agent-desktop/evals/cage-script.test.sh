#!/usr/bin/env bash
# Runs scripts/cage.sh against a fake cage, wtype and grim on PATH: no compositor, no
# window, no key reaches a real desktop.
# Usage: bash evals/cage-script.test.sh   (needs bash, python3)
set -uo pipefail
HERE=$(cd "$(dirname "$0")/.." && pwd)
DC="$HERE/scripts/cage.sh"
T=$(mktemp -d)
trap 'pkill -f "$T/rt/[w]ayland-fake" 2>/dev/null; rm -rf "$T"' EXIT
fails=0
# shellcheck disable=SC2053 # the third argument is a glob pattern
check() { if [[ "$2" == $3 ]]; then echo "ok   $1"; else echo "FAIL $1: got '$2', want '$3'"; fails=$((fails + 1)); fi; }

mkdir -p "$T/bin" "$T/home" "$T/rt"
# The fake cage binds a real unix socket, as the guard tests for one, then runs the command after
# "--" with WAYLAND_DISPLAY set, the way cage does. Its shebang names bash directly: through env,
# the kernel would call the process "bash", and the script looks for a process called "cage".
cat >"$T/bin/cage" <<'FAKE'
#!/bin/bash
[ "$1" = "--" ] && shift
sock=wayland-fake-$$
python3 -c 'import socket,sys,time; s=socket.socket(socket.AF_UNIX); s.bind(sys.argv[1]); time.sleep(600)' "$XDG_RUNTIME_DIR/$sock" &
for _ in $(seq 50); do [ -S "$XDG_RUNTIME_DIR/$sock" ] && break; sleep 0.1; done
echo "backends=${WLR_BACKENDS:-} renderer=${WLR_RENDERER:-}" >"$FAKE_DIR/cage.env"
WAYLAND_DISPLAY=$sock "$@" &
wait
FAKE
cat >"$T/bin/wtype" <<'FAKE'
#!/usr/bin/env bash
echo "display=$WAYLAND_DISPLAY args=$*" >>"$FAKE_DIR/wtype.log"
FAKE
cat >"$T/bin/grim" <<'FAKE'
#!/usr/bin/env bash
echo "display=$WAYLAND_DISPLAY" >>"$FAKE_DIR/grim.log"
echo png >"$1"
FAKE
chmod +x "$T/bin/"*

run() { env -u HYPRLAND_INSTANCE_SIGNATURE PATH="$T/bin:$PATH" FAKE_DIR="$T" AGENT_DESKTOP_CAGE_HOME="$T/home" XDG_RUNTIME_DIR="$T/rt" WAYLAND_DISPLAY=wayland-host bash "$DC" "$@"; }

out=$(run type calc hello); code=$?
check "type refuses a session that never started" "$out" "REFUSED name=calc reason=no-session"
check "a refusal exits 3" "$code" "3"

out=$(run start calc -- sleep 300)
check "start reports the session" "$out" "STARTED name=calc mode=headless size=1280x720 socket=wayland-fake-* pid=* log=*"
sock=$(cat "$T/home/calc.sock")
check "headless start uses the headless backend and leaves the renderer to wlroots" "$(cat "$T/cage.env")" "backends=headless renderer="
check "a second start leaves the live session alone" "$(run start calc -- sleep 300)" "ALREADY name=calc *"
check "status lists the live session" "$(run status)" "name=calc alive=yes mode=headless socket=$sock *"

out=$(run type calc "-8*2")
check "type reports the character count" "$out" "TYPED name=calc chars=4"
check "type sends the text to the session's socket, after --" "$(tail -n 1 "$T/wtype.log")" "display=$sock args=-- -8\*2"

run key calc Return ctrl+a ctrl+shift+Tab x >/dev/null
check "a named key goes through -k" "$(sed -n 2p "$T/wtype.log")" "display=$sock args=-k Return"
check "a modifier and one character" "$(sed -n 3p "$T/wtype.log")" "display=$sock args=-M ctrl -- a"
check "two modifiers and a named key" "$(sed -n 4p "$T/wtype.log")" "display=$sock args=-M ctrl -M shift -k Tab"
check "one character alone" "$(sed -n 5p "$T/wtype.log")" "display=$sock args=-- x"

out=$(run shot calc "$T/out/proof.png")
check "shot saves the file it names" "$out" "SHOT name=calc file=$T/out/proof.png"
check "shot reads the session's socket" "$(cat "$T/grim.log")" "display=$sock"
# The guard: a session file that names the caller's own display must send nothing.
lines=$(wc -l <"$T/wtype.log")
echo wayland-host >"$T/home/calc.sock"
out=$(run type calc "rm -rf"); code=$?
check "type refuses the caller's own display" "$out" "REFUSED name=calc reason=socket-is-the-callers-display"
check "that refusal exits 3" "$code" "3"
check "key refuses it too" "$(run key calc Return)" "REFUSED name=calc reason=socket-is-the-callers-display"
check "shot refuses it too" "$(run shot calc "$T/out/no.png")" "REFUSED name=calc reason=socket-is-the-callers-display"
echo ../evil >"$T/home/calc.sock"
check "a socket name with a slash is refused" "$(run type calc x)" "REFUSED name=calc reason=socket-name-has-a-slash"
echo wayland-gone >"$T/home/calc.sock"
check "a socket that does not exist is refused" "$(run type calc x)" "REFUSED name=calc reason=socket-missing"
check "no refused call reached wtype" "$(wc -l <"$T/wtype.log")" "$lines"
echo "$sock" >"$T/home/calc.sock"

# --size on a headless session goes through wlr-randr, and says so when it is missing.
out=$(run start sized --size 420x640 -- sleep 300)
check "headless --size without wlr-randr keeps 1280x720" "$(sed -n 1p <<<"$out")" "STARTED name=sized mode=headless size=1280x720 *"
check "and warns about it" "$(sed -n 2p <<<"$out")" "warn wlr-randr is not installed*"
run stop sized >/dev/null
cat >"$T/bin/wlr-randr" <<'FAKE'
#!/usr/bin/env bash
[ $# -eq 0 ] && { echo 'HEADLESS-1 "Headless output 1"'; exit 0; }
echo "display=$WAYLAND_DISPLAY args=$*" >>"$FAKE_DIR/randr.log"
FAKE
chmod +x "$T/bin/wlr-randr"
out=$(run start sized --size 420x640 -- sleep 300)
check "headless --size with wlr-randr reports the size" "$out" "STARTED name=sized mode=headless size=420x640 *"
check "wlr-randr sets the mode on the session's output" "$(cat "$T/randr.log")" "display=$(cat "$T/home/sized.sock") args=--output HEADLESS-1 --custom-mode 420x640"
run stop sized >/dev/null
check "a size that is not WxH is rejected" "$(run start sized --size big -- sleep 1 2>&1)" "*--size takes WxH*"

check "a bad name is rejected" "$(run start 'Bad Name' -- sleep 1 2>&1)" "*NAME is 1 to 32*"
pid=$(cat "$T/home/calc.pid")
check "stop ends the session" "$(run stop calc)" "STOPPED name=calc"
check "stop kills the cage" "$([[ -d /proc/$pid ]] && echo alive || echo gone)" "gone"
check "type refuses after stop" "$(run type calc x)" "REFUSED name=calc reason=no-session"
check "status is empty after stop" "$(run status)" "NONE"
check "a second stop says so" "$(run stop calc)" "NOT_RUNNING name=calc"

echo
if ((fails)); then echo "$fails failed"; exit 1; fi
echo "all passed"
