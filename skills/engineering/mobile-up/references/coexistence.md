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
| busy emulator | the `initialUri` line: which Metro, launched when |

Commands that take out more than intended: `lsof -ti:PORT` and `lsof -ti tcp:PORT` (both match
clients connected to the port; `-sTCP:LISTEN` keeps only the listener), `pkill -f <pattern>`
(matches the shell running it), `adb emu kill` without `-s`.

## The emulator is one device

Before opening the app, the `emulator` target reads which Metro the app on screen came from (the
last `Running "main"` line in logcat). Another port there, with the app in the foreground, means
another session is driving the emulator: the script reports `busy` and exits 6 without touching
it. Ask the user; on yes, rerun with `--take-emulator`.

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
