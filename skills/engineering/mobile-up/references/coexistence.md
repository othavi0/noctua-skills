# Several sessions, one machine

Ports, `adb` and the emulator are machine-wide. Two checkouts of the same project (a worktree per
task is the normal way to work) meet on 8081 and on the API port, and on the one AVD.

## Ports: reuse by owner, never by number

A port in LISTEN says nothing about who serves it. The script reads the listener's pid and working
directory and reuses it only when the directory is under this checkout. A listener from another
checkout is a **foreign** process:

- the script leaves it alone and starts on the next free port (`3001` taken → `3002`, `8081` →
  `8082`), and the env, the `exp://` URL and the QR follow the new port;
- on the next run it finds its own earlier server again by owner, so ports stay stable per checkout;
- `status` prints the owner of the server port and of the Metro port, with cwd and age.

Two `next dev` on the same directory cannot coexist (Next refuses the second one); that is why
reuse by owner matters more than a free port.

## Restarts are the user's

A dev process that is up was started by someone: the user, an earlier turn, another session. The
skill never kills one on its own judgement. The warnings that justify asking, with the evidence to
put in the question:

| Warning | Evidence in the question |
|---|---|
| bundle is stale | pid, the URL Metro was started with, the URL the env has now |
| started before HEAD | pid, start time, the HEAD commit line, what looks stale |
| busy emulator | which Metro the app came from (Expo Go: the `initialUri` line, launched when; dev client: the `url=` of the task's launch intent) |

Commands that take out more than intended: `lsof -ti:PORT` and `lsof -ti tcp:PORT` (both match
clients connected to the port; `-sTCP:LISTEN` keeps only the listener), `pkill -f <pattern>`
(matches the shell running it), `adb emu kill` without `-s`.

## The emulator is one device

Before opening the app, the `emulator` target reads which Metro the app in the foreground came
from, whatever client this project uses: a clock-in run must see a barembar dev client on screen,
and the other way round. Expo Go in the foreground: the last `Running "main"` line in logcat. Any
other app: the `url=` of a dev client link in the launch intent of its task (`dumpsys activity
activities`), since a dev client logs that line without an `initialUri`; `localhost` there (through
`adb reverse`) counts as the host machine, the same as `10.0.2.2`. Another port means another
session is driving the emulator: the script reports `busy` and exits 6 without touching it. Ask
the user; on yes, rerun with `--take-emulator`. An app opened from the launcher carries no URL, and
the check lets it through.

Projects that live on different AVDs set `AVD` in their own `.claude/mobile-up.conf`: the script
then picks the emulator booted from that AVD even when another one is running, instead of the
first `emulator-N` that `adb devices` lists.

A second session that only needs Metro for a side effect (Expo Router generates its route types
when the dev server starts) starts its own on a spare port and stops that one itself, or skips
Metro with `npx expo customize tsconfig.json`, which writes the types without a server:

```bash
cd <app> && npx expo start --port 8099   # generate .expo/types, then kill this pid: it is yours
```

## State and logs are per checkout

`~/.cache/mobile-up/<slug>.state` and the three logs use a slug built from the main checkout's
name plus the worktree's (`clock-in-feature-x`), so sessions do not overwrite each other's record
of pids and bundle URLs.
