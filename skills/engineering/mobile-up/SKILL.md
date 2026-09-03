---
name: mobile-up
description: |
  Use when invoking `/mobile-up [server|app|emulator|status]`, or when asked to run, start, open,
  serve or test an Expo app: on a phone with Expo Go, on an Android emulator, or just its dev
  server. Also use when the app on a device shows a network error, a blank screen, a bundle that
  never loads, "incompatible with this version of Expo Go", or when a server that should be up
  is not answering.
when_to_use: |
  "run the app", "test it on my phone", "open the emulator", "bring everything up", "the app
  can't reach the API", "who is holding port 8081". Not for a web-only dev server on an arbitrary
  port (that is dev-up), and not for running the test suite. Linux host only; on macOS or Windows
  follow references/other-platforms.md by hand instead of running the script.
argument-hint: "[server|app|emulator|status]"
allowed-tools: Bash(bash ${CLAUDE_SKILL_DIR}/scripts/mobile-up.sh *)
disable-model-invocation: true
compatibility: Linux host for the script (bash, ss, ip, curl). Android SDK for the emulator target. macOS and Windows hosts follow references/other-platforms.md by hand.
---

# mobile-up

One command brings up the pair an Expo app needs (dev server + Metro), syncs the machine's LAN IP
into the app's env, proves each piece answers, and hands back the addresses. The deterministic
part lives in `scripts/mobile-up.sh`; the judgement calls live here. Run the script instead of
redoing its steps by hand: several of them have cost a session before (see Red flags below).

## Targets

| Target | Brings up | Reach for it when |
|---|---|---|
| `server` | dev server | web-only or API-only work |
| `app` (default) | dev server + Metro, QR on screen | the user tests on a phone with Expo Go |
| `emulator` | dev server + Metro + Android AVD, app opened with a fresh bundle | you drive the app yourself and capture the screen |
| `status` | nothing (read-only) | something should be up and is not; who owns a port; what the bundle was built with |

When the app consumes a local API, Metro alone opens it on a screen with no data, so `app`
and `emulator` include the server. A project without a local API sets `SERVER=none` (see
`references/config.md`).

## Run it

1. **Run with the Bash tool's background flag** and read the whole output once the run ends:

   ```bash
   bash ${CLAUDE_SKILL_DIR}/scripts/mobile-up.sh app
   ```

   Done when the block starting `== mobile-up: <target>` is in front of you, read top to bottom,
   unfiltered. Progress lines come first, the summary block last; inside it the status lines come
   before the QR, which is the only tall part. A pipe into `tail` or `grep` is how one session
   lost the whole output.
2. **Exit code other than 0**: the message names the cause (missing tool, ambiguous project, port
   with no free neighbour, timeout with a log excerpt). Report the excerpt verbatim, then fix the
   named cause; `references/config.md` lists the codes.
3. **Every line under `warnings:` needs an action** before the handback:
   - *bundle is stale* or *not the one mobile-up recorded*: the env is baked into the bundle when
     Metro starts, so the app on air talks to the old URL. Restart is the user's call (below).
   - *started before the current HEAD commit*: hot reload covers app code, not always workspace
     packages. Only worth a restart when behaviour looks stale; ask then.
   - *Expo Go X vs project SDK Y*: propose the install line the script printed (below).
   - *default route goes through a VPN interface* or *no LAN IP*: rerun with
     `MOBILE_UP_IP=<lan-ip>`.
   - *no dev server workspace found* or *no EXPO_PUBLIC_*URL variable*: right for an app without a
     local API; otherwise set `SERVER_DIR` or `ENV_VAR` in the project config.
   - *server .env missing*: the server may fail on its secrets; the hint names the file to link.
   - *dev script has no literal port*: the alternate port went in as `PORT=`; check the log for
     the port it bound.
   - *adb sees a device that is not ready*: `offline` or `unauthorized`; accept the USB prompt on
     the phone or unplug it before the emulator run.

   A port held by a foreign process is a progress line, not a warning: the summary shows the
   port used.

## Handback

The servers belong to the user and stay up until the user asks you to stop them; say so. Report,
by target:

- `server`: the two URLs (localhost and LAN), the env line, the log path, the state path.
- `app`: the above plus the `exp://` URL and the QR exactly as printed, and the firewall commands
  if the script printed them (they need sudo: the user runs them).
- `emulator`: the above plus the serial, the `adb` path, the `bundle delivered after Ns` line, and
  one screenshot you have read (`references/android.md`). A summary line is not proof that the
  screen shows the app.

Ports can move: when the base port belongs to another checkout, the script picks the next free one
and the `exp://` URL and the env move with it. Read them from the summary, never from memory.

## Ownership

The script reuses a listener only when its working directory is under this checkout. Anything else
is a foreign process, left alone. Restarting a dev server or Metro that is already up is a decision
the user makes, whatever started it:

1. Put the evidence in one `AskUserQuestion`: pid, cwd, age, the warning line, and both paths
   with their cost (restart: a fresh bundle, ~30 s; keep: the stale behaviour named in the
   warning).
2. On yes, run the exact line the script printed (`kill <pid> && rerun mobile-up`). The pid is
   the listener from the state file; `status` confirms it still owns the port. `lsof -ti:PORT`
   matches clients connected to the port as well (only `-sTCP:LISTEN` narrows it to the listener),
   and `adb emu kill` without `-s` takes down whichever emulator is on the machine.

`kill` and `adb ... emu kill` are outside `allowed-tools` on purpose: they are not part of the
pre-approved `mobile-up.sh` invocation, so the harness prompts for approval on both, and that
prompt is the intended gate on killing a process, not a bug to route around.

`status` answers most "is it up?" questions without touching anything.

## Missing dependency

Project dependencies are routine: run the package manager's install and rerun. Tools on the
machine are different: name what is missing and where it officially comes from, then ask before
installing. Install commands differ per platform, so the user picks the way in. The sources:

- Expo Go on a device or emulator: `npx expo-go download android <sdk>` (the script prints the
  line with the project's SDK), or https://expo.dev/go.
- Android SDK, `adb`, emulator: Android Studio or the command-line tools at
  https://developer.android.com/studio; the script finds them via `ANDROID_HOME`,
  `ANDROID_SDK_ROOT`, `~/Android/Sdk`, or `adb` on PATH.
- `qrencode`: the platform's package named `qrencode`; without it the script prints the URL to
  type into Expo Go.

## Red flags

Each row is a rationalisation seen in a real session; the right column is the move that replaces it.

| Thought | Move |
|---|---|
| "I'll run it in the foreground with `tail`, it's quick" | Background flag, then read the whole output. |
| "The 403 is what the plan predicted, dispatch the fix" | Run `status` first: a server older than the packages it serves explains most stale behaviour. |
| "It hung on the QR step, probably" | Read the log the summary names; a guess without a command is not a diagnosis. |
| "Port 3001 is mine, kill it" | `status` shows the owner's cwd. Foreign cwd: ask. |
| "The screenshot is there, moving on" | Read it. An unread capture proves nothing. |
| "Same coordinates as before, tap" | Capture, read, then tap (`references/android.md`). |

## Deeper

- Device or emulator will not load, shows an error, or connects and stays blank:
  `references/troubleshooting.md` (one entry per symptom).
- Driving the app on the emulator: taps, holds, screenshots, deep links to a route, fresh bundle,
  keyboard quirks: `references/android.md`.
- Several sessions or worktrees on one machine, one emulator: `references/coexistence.md`.
- Project detection, config keys, state file, logs, exit codes: `references/config.md`.
- macOS or Windows host: `references/other-platforms.md`.

## Shutting down

Only when the user asks. `kill` the `SERVER_PID` and `METRO_PID` from the state file; the emulator
stays unless they ask for it too (`adb -s <serial> emu kill`). Then remove the state file the
summary named.
