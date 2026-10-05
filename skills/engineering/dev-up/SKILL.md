---
name: dev-up
description: >-
  Starts a project's dev server pinned to one port, opens a browser tab you own on it, and arms a
  watcher on its log so you can hand control back and walk away. Use when invoking `/dev-up [port]`,
  or when asked to start, open, view, run, serve, restart, or monitor this project's dev server on a
  specific port, especially when other servers or browser tabs already run in parallel and must not
  be disturbed. Not for an Expo app on a phone or emulator, that is mobile-up.
# argument-hint, allowed-tools and hooks are Claude Code fields, not part of the Agent Skills spec.
# Drop them before uploading this folder to claude.ai or the Skills API.
argument-hint: "[port]"
allowed-tools:
  - Bash(bash ${CLAUDE_SKILL_DIR}/scripts/dev-up.sh owner *)
  - Bash(bash ${CLAUDE_SKILL_DIR}/scripts/dev-up.sh preflight *)
  - Bash(bash ${CLAUDE_SKILL_DIR}/scripts/dev-up.sh wait *)
  - Bash(bash ${CLAUDE_SKILL_DIR}/scripts/dev-up.sh watch *)
  - Bash(bash ${CLAUDE_SKILL_DIR}/scripts/dev-up.sh state *)
hooks:
  UserPromptSubmit:
    - hooks:
        - type: command
          command: 'p="$HOME/.cache/dev-up/dev-up.sh"; [ -f "$p" ] && bash "$p" unwatched; true'
---

# dev-up

One dev server on one **port**, one browser **tab** you own at that port, one **watcher** on the
log. The port is the key: the server binds it, the tab points at it, and every file in
`~/.cache/dev-up/` is named after it.

`scripts/dev-up.sh` does the mechanical part. Run it as `bash ${CLAUDE_SKILL_DIR}/scripts/dev-up.sh
<command> PORT`, exactly that path, so `allowed-tools` matches. Every command prints its verdict on
the first line (`FREE`, `READY`, `DIED`, ...). Write the state only through its `state` command.

`PORT` below is the literal port number.

## Invocation

- `/dev-up PORT`: the full flow below.
- The argument is a URL: open a tab on it (steps 4.1 to 4.2.5 with that URL). No server, watcher
  or state.
- No argument: a `.state` of this checkout with a live port → use that port and say so in one line.
  No `dev` script in the folder → say there is nothing to run. Otherwise ask for the port.
- Called in the middle of other work, as a proof step: run every step anyway. The handback becomes
  one line in that task's report.

## 1. Who holds the port

`owner PORT` prints `FREE`, or `BUSY pid=N cwd=DIR mine=... via=... state=...`:

- `FREE` → `state PORT init`, then step 2.
- `mine=yes state=mine` → this session already set it up. `state PORT show` says which piece is
  dead: re-run only that step (3 for the watcher, 4 for the tab).
- `mine=yes`, any other state → this checkout serves it. `state PORT init`, skip step 2. With
  `via=other` the server writes no log here, and the watcher only reports it going down.
- `mine=worktree` → another worktree of this repo serves different code. Ask the user: reuse it as
  is, or run Restart from this checkout.
- `mine=no` or `mine=?` → a foreign process. Leave it alone and ask the user.

## 2. Start the server

1. `preflight` in the app's directory. Run every `run` line it prints; a `todo` line needs a
   decision. A `warn pinned port` line means an auth callback or CORS origin expects another port:
   warn in one line and keep the user's port.
2. Find the dev command in the manifest. In a monorepo (`workspaces`, `turbo.json`,
   `pnpm-workspace.yaml`, `nx.json`) the root `dev` starts every app: list the workspaces with a
   `dev` script, ask with `AskUserQuestion` when there is more than one, and launch from that app's
   directory.
3. Pin the port with the framework's flag (`--port`, `-p`; add Vite's `--strictPort`) or the app's
   `PORT` env var. When the `dev` script already hardcodes a port, run the script's command itself
   with the number swapped and the env prefix kept: `TZ=UTC next dev -p 3001` becomes
   `TZ=UTC next dev -p PORT`. `serve` puts the local `node_modules/.bin` and `.venv/bin` first on
   `PATH`, so the bare binary name resolves. Leave `package.json` as is.
4. Launch with Bash `run_in_background: true`:

   ```bash
   bash ${CLAUDE_SKILL_DIR}/scripts/dev-up.sh serve PORT --dir <app dir> -- '<dev command>'
   ```

   Add `--mem 4G` when this machine has killed a dev server before: it runs the command under
   `systemd-run --user --scope` with that memory cap. After editing `.env` this session, prefix the
   command with `set -a; . ./.env; set +a;`. The background task ends when the server dies, and
   that exit is the death alarm, so launch only through `serve`. Then
   `state PORT set server_task=<task id>`.
5. Wait with a foreground Bash call and `timeout: 600000`: `wait PORT`. `READY` → step 3. Any other
   verdict (`DIED`, `HTTP_5XX`, `BUSY_OTHER`, `BOUND_NO_HTTP`, `TIMEOUT`) comes with the log tail:
   read it, then [`references/troubleshooting.md`](references/troubleshooting.md).

## 3. Arm the watcher

Load every deferred tool the run needs in one call:

```
ToolSearch "select:Monitor,TaskStop,mcp__claude-in-chrome__list_connected_browsers,mcp__claude-in-chrome__select_browser,mcp__claude-in-chrome__tabs_context_mcp,mcp__claude-in-chrome__tabs_create_mcp,mcp__claude-in-chrome__navigate,mcp__claude-in-chrome__read_console_messages,mcp__claude-in-chrome__read_network_requests,mcp__claude-in-chrome__browser_batch,mcp__claude-in-chrome__javascript_tool,mcp__claude-in-chrome__tabs_close_mcp"
```

No `mcp__claude-in-chrome__*` tool comes back → [`references/setup.md`](references/setup.md).

Arm one Monitor: command `bash ${CLAUDE_SKILL_DIR}/scripts/dev-up.sh watch PORT`, description
`errors on port PORT`, `timeout_ms: 1800000` (the tool's ceiling). Its return reads `Monitor started
(task <id>, ...)`: run `state PORT set watcher_task=<id>`. `state PORT show` reports
`watcher_alive` from the watcher's own process; `TaskList` never lists a Monitor.

- Expiry notice after an event or a user prompt since the last arm → re-arm now. A quiet expiry →
  let it lapse. On the user's next prompt the skill's hook prints `port PORT has no live watcher`;
  re-arm before answering.
- A real error → report it.
- A transient blip (DNS `EAI_AGAIN`, one failed external call, a `DeprecationWarning`) → ignore it.
- A recurring line that changes nothing the user sees → `state PORT exclude '<literal text from the
  line>'`, `TaskStop` the watcher, re-arm. Keep HMR errors (`ReferenceError`, `Module not found`)
  out of the excludes: after an edit they are real bugs.
- Before you or a subagent edits code this server serves, installs deps, or runs a migration:
  `TaskStop` the watcher and run `state PORT pause`, which keeps the hook quiet. Re-arm when that
  round ends (typecheck or tests green).

## 4. Pin the tab

1. Browser. `list_connected_browsers`, then keep only devices on this machine, since `localhost`
   resolves only here: `onThisComputer: true` when the field is present, else `isLocal: true`.
   - None local → ask the user to open this machine's browser and click Connect in the extension,
     then list again. The call errors → [`references/setup.md`](references/setup.md).
   - One local → use it.
   - Several local → read `${XDG_CONFIG_HOME:-$HOME/.config}/dev-up/browser` before any question.
     It holds `deviceId=` and `name=` lines. A device matching either one is the hit:
     `select_browser` with its current deviceId, or go straight on when it is already `inUse`.
     Miss → `AskUserQuestion` with the local devices, then write both lines for the pick.
     Details in [`references/browser-cache.md`](references/browser-cache.md).
2. Tab. Every call here waits for the previous one to return, on the same tab:
   1. `tabs_context_mcp` with `createIfEmpty: true`. Reuse a tab already at `localhost:PORT`, else
      `tabs_create_mcp`.
   2. `navigate` to `http://localhost:PORT`, the root, so a login redirect shows up first.
   3. One `browser_batch`: `read_console_messages`, `read_network_requests`, `navigate` to the
      root, `tabs_context_mcp`. The two reads start the recording, so they come back empty by
      design: never report them as a smoke result. The last call gives the real URL. A
      `browser-internal` error means step 2 had not landed: repeat steps 2 and 3.
   4. The URL ended on a login route (`/login`, `/auth`, `/sign-in`, `/entrar`, `/acesso`,
      `/conta`) → stop and ask the user to log in. Credentials are the user's to type, in the tab
      and in curl alike. Continue when they confirm, then navigate to the route you need.
   5. Smoke, one `browser_batch`: `read_console_messages` (`onlyErrors: true`,
      `pattern: "error|failed|exception"`), `read_network_requests` (`urlPattern: "/api"` or the
      app's data origin), and `javascript_tool` with `document.visibilityState`.
   6. `state PORT set tab_id=<id>`. This is `TARGET_TAB_ID`, the one tab you own. It stays on
      `localhost:PORT`; another server or a prototype gets its own tab
      ([`references/coexistence.md`](references/coexistence.md)).

Confirm a URL with `tabs_context_mcp`, never with a screenshot.

## 5. Hand back

`state PORT show` lists the task ids, the tab id, and whether server and watcher are alive. Report
the port, the log path, the tab id, the watcher id, and the smoke result: clean, the boot errors it
found, or `hidden`, which means screenshots and clicks stall until the user brings the tab forward.

## Restart

For new code, a new `.env`, or another worktree on the same port. Keep the port: the login cookie
belongs to `host:port`, so a new port logs the user out.

1. `owner PORT`. With `via=dev-up`, `stop PORT`, then `TaskStop` the `server_task` when this
   session started it. With `via=other`, ask the user first; on a yes, `stop PORT --force`.
2. `state PORT init` from the directory you will serve.
3. Another worktree → `preflight` there first.
4. Launch and wait as in step 2.4 and 2.5, with `--dir` pointing at the code to serve. `wait`
   answers `READY` only when the listener descends from this `serve`. Record the new `server_task`.
5. Re-arm the watcher only when `state PORT show` says it is dead. Navigate the tab to the root
   again.

## After setup

- Driving or debugging the app through the tab → [`references/interacting.md`](references/interacting.md).
- Startup trouble, lost login, a server killed without an error →
  [`references/troubleshooting.md`](references/troubleshooting.md).
- Back after a compaction, a restart or long subagent work → `owner PORT` and `state PORT show`,
  then re-run the step of each dead piece.

## Shutting down

Server, watcher and tab belong to the user and stay up until the user asks for a shutdown. Running
autonomously, leave them up and say so in the handback. When the user asks, follow
[`references/shutdown.md`](references/shutdown.md).
