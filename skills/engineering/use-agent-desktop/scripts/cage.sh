#!/usr/bin/env bash
# cage.sh: the mechanical half of the use-agent-desktop skill. One desktop app per session, each
# inside its own cage compositor. A cage has its own keyboard and its own Wayland socket, so keys
# typed into it cannot reach the user's desktop.
#
# Usage: cage.sh <command> [NAME] [args]
#   start NAME [--visible] [--size WxH] -- CMD [ARGS]
#                         run CMD inside a new cage: STARTED name=N mode=headless|visible size=WxH|window
#                         socket=S pid=P log=FILE. Headless draws nothing on the user's screen.
#                         --visible opens the cage as a window of the user's desktop; on Hyprland
#                         the window floats and does not take focus. cage stretches the app to
#                         its whole output, so --size gives the app the shape it was drawn for
#                         (default 1280x720). Headless --size needs wlr-randr; without it the
#                         start answers size=1280x720 and a "warn" line. The cage renders on the
#                         GPU when wlroots finds one; export WLR_RENDERER=pixman to force the CPU.
#                         ALREADY name=N when the session is alive. FAILED and the log tail when
#                         the cage gave no socket in 10 s
#   type NAME TEXT        type TEXT into the session: TYPED chars=N
#   key NAME KEY...       press each KEY in order: PRESSED n=N. A KEY is an xkb name (Return,
#                         Escape, BackSpace, Tab, Left, F5), one character, or a combination
#                         joined by "+" (ctrl+a, ctrl+shift+Tab). Modifiers: shift, ctrl, alt,
#                         logo, altgr
#   shot NAME [FILE]      save a PNG of the session's whole output: SHOT file=FILE. FILE defaults
#                         to NAME-<time>.png in the state directory
#   status [NAME]         one line per session: name, alive=yes|no, mode, socket, pid, cpu, rss
#   stop NAME             end the cage and its app: STOPPED name=N, or NOT_RUNNING name=N
#
# type, key and shot answer REFUSED reason=... and exit 3 unless the session's socket exists,
# belongs to a live cage, and differs from the WAYLAND_DISPLAY of the caller. That check is the
# reason this script exists: wtype with the wrong socket types into the user's focused window.
#
# State: $AGENT_DESKTOP_CAGE_HOME (default ~/.cache/use-agent-desktop) holds NAME.sock, NAME.pid, NAME.mode,
# NAME.log and NAME.launch.sh.
set -uo pipefail

D=${AGENT_DESKTOP_CAGE_HOME:-$HOME/.cache/use-agent-desktop}
RT=${XDG_RUNTIME_DIR:-/run/user/$(id -u)}
HOST=${WAYLAND_DISPLAY:-}

die() {
	echo "$*" >&2
	exit 2
}
need() { command -v "$1" >/dev/null 2>&1 || die "cage.sh: $1 is not installed"; }
name_ok() { [[ ${1:-} =~ ^[a-z0-9][a-z0-9-]{0,31}$ ]] || die "cage.sh: NAME is 1 to 32 lowercase letters, digits or hyphens"; }

pid_of() { cat "$D/$1.pid" 2>/dev/null; }
sock_of() { cat "$D/$1.sock" 2>/dev/null; }
alive() {
	local pid
	pid=$(pid_of "$1")
	[[ $pid =~ ^[0-9]+$ ]] && [[ $(cat "/proc/$pid/comm" 2>/dev/null) == cage ]]
}

# The socket of a live session, or REFUSED. Every command that sends input or reads the screen
# goes through here first.
guard() {
	local name=$1 sock
	sock=$(sock_of "$name")
	refuse() {
		echo "REFUSED name=$name reason=$1"
		exit 3
	}
	[[ -n $sock ]] || refuse no-session
	alive "$name" || refuse cage-not-running
	[[ $sock != */* ]] || refuse socket-name-has-a-slash
	[[ $sock != "$HOST" ]] || refuse socket-is-the-callers-display
	[[ -S $RT/$sock ]] || refuse socket-missing
	SOCK=$sock
}

cmd_start() {
	local name=${1:-} mode=headless size=""
	name_ok "$name"
	shift
	while (($#)) && [[ $1 != -- ]]; do
		case $1 in
		--visible) mode=visible ;;
		--size)
			size=${2:-}
			[[ $size =~ ^[0-9]+x[0-9]+$ ]] || die "cage.sh: --size takes WxH, like 420x640"
			shift
			;;
		*) die "cage.sh: unknown option $1" ;;
		esac
		shift
	done
	[[ ${1:-} == -- ]] && shift
	(($#)) || die "cage.sh: start NAME [--visible] [--size WxH] -- CMD [ARGS]"
	need cage
	if alive "$name"; then
		echo "ALREADY name=$name socket=$(sock_of "$name") pid=$(pid_of "$name")"
		return 0
	fi
	mkdir -p "$D"
	rm -f "$D/$name".{sock,pid,mode}
	local launch=$D/$name.launch.sh log=$D/$name.log env_line="" rule="float = true, no_initial_focus = true"
	[[ $mode == headless ]] && env_line="export WLR_BACKENDS=headless WLR_LIBINPUT_NO_DEVICES=1"
	# The app writes the cage's socket name before it starts. Qt apps join the accessibility bus
	# only with QT_LINUX_ACCESSIBILITY_ALWAYS_ON, and agent-desktop needs that bus.
	{
		echo '#!/usr/bin/env bash'
		echo "cd ${PWD@Q} || exit 1"
		echo "$env_line"
		echo "echo \$\$ >${D@Q}/$name.pid"
		echo "exec cage -- sh -c 'echo \"\$WAYLAND_DISPLAY\" >\"\$0\"; exec env QT_LINUX_ACCESSIBILITY_ALWAYS_ON=1 QT_QPA_PLATFORM=wayland \"\$@\"' ${D@Q}/$name.sock ${*@Q} >${log@Q} 2>&1"
	} >"$launch"
	chmod +x "$launch"
	echo "$mode" >"$D/$name.mode"
	if [[ $mode == visible && -n ${HYPRLAND_INSTANCE_SIGNATURE:-} ]] && command -v hyprctl >/dev/null 2>&1; then
		[[ -n $size ]] && rule+=", size = { ${size/x/, } }"
		hyprctl dispatch "hl.dsp.exec_cmd(\"$launch\", { $rule })" >/dev/null
	else
		setsid nohup "$launch" >/dev/null 2>&1 </dev/null &
	fi
	local sock=""
	for _ in {1..50}; do
		sock=$(sock_of "$name")
		[[ -n $sock && -S $RT/$sock ]] && alive "$name" && break
		sleep 0.2
	done
	if [[ -z $sock || ! -S $RT/$sock || $sock == "$HOST" ]] || ! alive "$name"; then
		echo "FAILED name=$name log=$log"
		tail -n 15 "$log" 2>/dev/null
		return 1
	fi
	local warn=""
	if [[ $mode == headless && -n $size ]]; then
		if command -v wlr-randr >/dev/null 2>&1; then
			local out
			out=$(WAYLAND_DISPLAY=$sock wlr-randr | awk 'NR==1{print $1}')
			WAYLAND_DISPLAY=$sock wlr-randr --output "$out" --custom-mode "$size" >/dev/null 2>&1 || warn="wlr-randr refused $size"
		else
			warn="wlr-randr is not installed, so the output stays 1280x720"
		fi
		[[ -n $warn ]] && size=1280x720
	fi
	[[ -n $size ]] || { [[ $mode == headless ]] && size=1280x720 || size=window; }
	echo "STARTED name=$name mode=$mode size=$size socket=$sock pid=$(pid_of "$name") log=$log"
	[[ -z $warn ]] || echo "warn $warn"
}

cmd_type() {
	local name=${1:-}
	name_ok "$name"
	[[ $# -ge 2 ]] || die "cage.sh: type NAME TEXT"
	need wtype
	guard "$name"
	WAYLAND_DISPLAY=$SOCK wtype -- "$2" || {
		echo "FAILED name=$name"
		return 1
	}
	echo "TYPED name=$name chars=${#2}"
}

cmd_key() {
	local name=${1:-} n=0
	name_ok "$name"
	shift
	(($#)) || die "cage.sh: key NAME KEY..."
	need wtype
	guard "$name"
	local key part args last
	for key in "$@"; do
		args=()
		IFS=+ read -r -a part <<<"$key"
		last=${part[-1]}
		unset 'part[-1]'
		for m in "${part[@]}"; do args+=(-M "$m"); done
		if [[ ${#last} == 1 ]]; then args+=(-- "$last"); else args+=(-k "$last"); fi
		# wtype releases every held modifier when it exits, so each KEY gets its own call.
		WAYLAND_DISPLAY=$SOCK wtype "${args[@]}" || {
			echo "FAILED name=$name key=$key"
			return 1
		}
		n=$((n + 1))
	done
	echo "PRESSED name=$name n=$n"
}

cmd_shot() {
	local name=${1:-}
	name_ok "$name"
	need grim
	guard "$name"
	local file=${2:-$D/$name-$(date +%Y%m%d-%H%M%S).png}
	mkdir -p "$(dirname "$file")"
	WAYLAND_DISPLAY=$SOCK grim "$file" || {
		echo "FAILED name=$name"
		return 1
	}
	echo "SHOT name=$name file=$file"
}

cmd_status() {
	local f name pid found=0
	for f in "$D"/${1:-*}.pid; do
		[[ -e $f ]] || continue
		found=1
		name=$(basename "$f" .pid)
		pid=$(pid_of "$name")
		if alive "$name"; then
			echo "name=$name alive=yes mode=$(cat "$D/$name.mode" 2>/dev/null) socket=$(sock_of "$name") pid=$pid $(ps -o pcpu=,rss= -p "$pid" | awk '{printf "cpu=%s%% rss=%.0fMB", $1, $2 / 1024}')"
		else
			echo "name=$name alive=no"
		fi
	done
	((found)) || echo "NONE"
}

cmd_stop() {
	local name=${1:-} pid
	name_ok "$name"
	if ! alive "$name"; then
		rm -f "$D/$name".{sock,pid,mode,launch.sh}
		echo "NOT_RUNNING name=$name"
		return 0
	fi
	pid=$(pid_of "$name")
	kill "$pid" 2>/dev/null
	for _ in {1..25}; do
		[[ -d /proc/$pid ]] || break
		sleep 0.2
	done
	[[ -d /proc/$pid ]] && kill -9 "$pid" 2>/dev/null
	rm -f "$D/$name".{sock,pid,mode,launch.sh}
	echo "STOPPED name=$name"
}

cmd=${1:-}
[[ $# -gt 0 ]] && shift
case $cmd in
start) cmd_start "$@" ;;
type) cmd_type "$@" ;;
key) cmd_key "$@" ;;
shot) cmd_shot "$@" ;;
status) cmd_status "$@" ;;
stop) cmd_stop "$@" ;;
*)
	sed -n '2,/^set -uo/p' "$0" | sed '$d; s/^# \{0,1\}//'
	[[ -z $cmd || $cmd == help ]]
	;;
esac
