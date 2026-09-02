# Detection, configuration, state, exit codes

The script reads the project instead of asking. Config exists for the cases detection cannot
settle. Inside the repository it writes only the app's `.env` and, in a linked worktree without
dependencies, `node_modules` symlinks to the main checkout.

## What the script detects

| Value | How |
|---|---|
| Root | `git rev-parse --show-toplevel`, else the current directory |
| Package manager | `bun.lock`/`bun.lockb` → bun; `pnpm-lock.yaml` → pnpm; `yarn.lock` → yarn; else npm |
| App directory | the `package.json` (depth ≤ 3, outside `node_modules`) that depends on `expo`; exactly one, or config |
| Dev server directory | a `package.json` with a `dev` script that is not the app and not a workspace root; ties broken by a known server dependency (`next`, `hono`, `express`, `fastify`, `@nestjs/core`, `koa`); still ambiguous → config |
| Dev server port | `--port N`, `-p N` or `PORT=N` in the server's `dev` script; else 3000 for Next, 5173 for Vite; else config |
| Metro port | `--port N` in the app's `dev` script, else 8081 |
| URL variable | the single `EXPO_PUBLIC_*URL` name in the app's `.env` (then `.env.example`); several → config |
| LAN IP | `ip -4 route get 1.1.1.1` (`src` and `dev`); a tunnel-looking interface raises a warning |
| Network range | `ip -o -4 route show dev <iface> scope link`, so the firewall hint uses the real prefix |
| Android SDK | `~/.config/mobile-up/machine.conf`, `ANDROID_HOME`, `ANDROID_SDK_ROOT`, `~/Android/Sdk`, `adb` on PATH |
| AVD home | machine config, then the first of `ANDROID_AVD_HOME`, `$ANDROID_USER_HOME/avd`, `~/.android/avd`, `~/.config/.android/avd` holding a `.ini` |
| AVD | machine config; else the only one listed; several → config |
| Emulator serial | `adb devices`, the first `emulator-N` in state `device`; every call then uses `-s` |

## Preflight

- Missing `node_modules` in a linked worktree: when the lockfile equals the main checkout's, the
  script symlinks every `node_modules` from there and says so; otherwise it stops and names the
  install command.
- Missing app `.env`: created from `.env.example` (or empty) before the URL is written.
- Missing server `.env` with an `.env.example` beside it: a warning, with the `ln -s` from the main
  checkout when one exists. Secrets are never copied by the script.

## Project config: `.claude/mobile-up.conf` (versioned)

`KEY=value`, one per line. Every key is optional.

| Key | Meaning |
|---|---|
| `APP_DIR` | Expo app directory, relative to the root |
| `SERVER_DIR` | dev server directory |
| `SERVER=none` | the app has no local server: Metro only |
| `SERVER_CMD` | command that starts the server (default `<pm> run dev` in `SERVER_DIR`) |
| `SERVER_PORT` | port the server binds |
| `METRO_PORT` | port Metro binds (default 8081) |
| `ENV_FILE` | app env file (default `<APP_DIR>/.env`) |
| `ENV_VAR` | the variable that carries the server URL |
| `PM` | package manager override |
| `SERVER_TIMEOUT`, `METRO_TIMEOUT`, `BOOT_TIMEOUT` | seconds to wait for bind / bind / emulator boot (90 / 120 / 360). Fixed: 60 s for the server's first HTTP answer, 60 s for Metro's `/status`, 120 s for the `Bundled` line |

## Machine config: `~/.config/mobile-up/machine.conf` (never versioned)

| Key | Meaning |
|---|---|
| `ANDROID_HOME` | SDK root |
| `ANDROID_AVD_HOME` | directory holding the `.avd` folders when the emulator cannot find them (`Unknown AVD name`) |
| `AVD` | AVD to boot when several exist |

Environment: `MOBILE_UP_IP=<ip>` overrides the detected LAN IP for one run.

Arguments: `--server-port N`, `--metro-port N` override the base ports for one run;
`--take-emulator` replaces an app another Metro opened on the emulator (after the user said yes).

## Alternate port

When the base port belongs to a foreign process, the next free port above it (up to +20) is used. The server
command is rebuilt by replacing the literal port in the `dev` script (`next dev --port 3001` →
`--port 3002`); a script with no literal port runs with `PORT=<alt>` and a warning. Metro on an
alternate port runs `expo start --clear --port <alt>` from the app directory.

## State: `~/.cache/mobile-up/<slug>.state`

`KEY=value`: `TARGET`, `TIME`, `ROOT`, `IP`, `SERVER_PORT`, `SERVER_PID`, `METRO_PORT`,
`METRO_PID`, `METRO_URL` (the URL baked into the running bundle), `ENV_FILE`, `ENV_VAR`, `URL`,
`ADB`, `SERIAL`, `AVD`, `EXPO_GO`, `LOG_SERVER`, `LOG_METRO`, `LOG_AVD`. The slug is the main
checkout's name, plus the worktree's name in a linked worktree.

Logs: `~/.cache/mobile-up/<slug>-server.log`, `-metro.log`, `-avd.log`. `~/.cache` rather than
`/tmp`: a full `/tmp` takes the shell down with it.

## Exit codes

| Code | Meaning |
|---|---|
| 0 | every requested piece answered |
| 2 | usage error, host is not Linux, or `ss`, `ip` or `curl` is missing |
| 3 | project not detected, ambiguous, or preflight failed (dependencies) |
| 4 | server did not bind, did not answer HTTP (log excerpt printed), no free port above the base, or the env variable could not be written |
| 5 | Metro did not bind, `/status` never said running, or no free port above the base |
| 6 | emulator: SDK, emulator binary or AVD missing, several AVDs without `AVD` set, boot timeout, Expo Go missing, `am start` failed, busy with another Metro, or no `Bundled` line |

The summary is printed even on 6, so the server and Metro lines stay usable.
