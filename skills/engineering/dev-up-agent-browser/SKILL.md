---
name: dev-up-agent-browser
description: >-
  Runs a project's dev server on one port and drives the app through an agent-browser session
  (headless, a visible window on request), with a watcher on the server log. Use for
  `/dev-up-agent-browser [port]`, to test or check a local app with agent-browser, or to let
  several agents test local apps at once on little RAM. The Claude in Chrome tab is dev-up; an
  Expo app on a device is mobile-up.
# argument-hint, allowed-tools and hooks are Claude Code fields, not part of the Agent Skills spec.
argument-hint: "[port]"
allowed-tools:
  - Bash(bash ${CLAUDE_SKILL_DIR}/scripts/dev-up.sh owner *)
  - Bash(bash ${CLAUDE_SKILL_DIR}/scripts/dev-up.sh preflight *)
  - Bash(bash ${CLAUDE_SKILL_DIR}/scripts/dev-up.sh wait *)
  - Bash(bash ${CLAUDE_SKILL_DIR}/scripts/dev-up.sh watch *)
  - Bash(bash ${CLAUDE_SKILL_DIR}/scripts/dev-up.sh state *)
  - Bash(bash ${CLAUDE_SKILL_DIR}/scripts/dev-up.sh ab *)
  - Bash(bash ${CLAUDE_SKILL_DIR}/scripts/dev-up.sh show *)
  - Bash(bash ${CLAUDE_SKILL_DIR}/scripts/dev-up.sh hide *)
  - Bash(bash ${CLAUDE_SKILL_DIR}/scripts/dev-up.sh dash)
  - Bash(bash ${CLAUDE_SKILL_DIR}/scripts/dev-up.sh browser *)
hooks:
  UserPromptSubmit:
    - hooks:
        - type: command
          command: 'p="$HOME/.cache/dev-up-ab/dev-up.sh"; [ -f "$p" ] && bash "$p" unwatched; true'
---

# dev-up-agent-browser

One dev server on one **port**, one agent-browser **session** named `devup-PORT`, one **watcher**
on the server log. The port is the key: the server binds it, the session is named after it, and so
is every file in `~/.cache/dev-up-ab/`. The session's profile and saved login live in
`~/.local/state/dev-up-ab/`, so a login outlives the browser.

`S` below is `bash ${CLAUDE_SKILL_DIR}/scripts/dev-up.sh`, written out in full on every call so
`allowed-tools` matches. Each command prints its verdict on the first line (`FREE`, `READY`,
`SWITCHED`, ...). `PORT` is the literal port number.

## The one rule: every browser call goes through `S ab PORT`

agent-browser keeps one daemon per session and **relaunches** the browser whenever a call's launch
options differ from the running ones: the page falls back to `about:blank`, or the visible window
comes back without its class and takes focus. `S ab PORT <agent-browser command>` sends the same
session, profile, executable and window class on every call, so the browser launched by `open`
serves every later call.

Needs `agent-browser` on `PATH`. Headless runs the newest Playwright `chrome-headless-shell` when
one is installed (`npx playwright install chromium-headless-shell`): measured at 176 MB per session
against 350 MB for a full Brave, at the same 7 to 10 ms per click. Without it, the session uses
`AGENT_BROWSER_EXECUTABLE_PATH` or agent-browser's own Chrome. `S browser PORT` prints what the
session runs.

## Invocation

- `/dev-up-agent-browser PORT`: steps 1 to 6.
- A URL: its port is the key (80 or 443 when it has none); run step 4 with that URL. No server,
  watcher or state.
- No argument: a `.state` of this checkout with a live port: use that port and say so in one line.
  No `dev` script in the folder: say there is nothing to run. Otherwise ask for the port.
- Called inside other work as a proof step: run every step; the handback becomes one line in that
  task's report.

## 1. Who holds the port

`S owner PORT` prints `FREE`, or `BUSY pid=N cwd=DIR mine=... via=... state=...`:

- `FREE`: `S state PORT init`, then step 2.
- `mine=yes state=mine`: this session set it up already. `S state PORT show` names the dead piece;
  re-run only its step (3 for the watcher, 4 for the browser).
- `mine=yes`, another state: this checkout serves it. `S state PORT init`, skip step 2. With
  `via=other` the server logs elsewhere, and the watcher reports only the server going down.
- `mine=worktree`: another worktree of this repo serves different code. Ask the user: reuse it, or
  Restart from this checkout.
- `mine=orphan`: the server's directory was deleted. `S stop PORT`, tell the user the PID and cwd it
  prints, then `S state PORT init` and step 2.
- `mine=no` or `mine=?`: a foreign process. Leave it running and take the next port up that `owner`
  calls `FREE`; tell the user in one line which process holds the port they asked for.

Done when `S state PORT show` prints this checkout's `dir`.

## 2. Start the server

1. `S preflight` in the app's directory. Run every `run` line; a `todo` line needs a decision.
   `warn pinned port`: an auth callback or CORS origin expects another port; say so in one line and
   keep the user's port. `warn served`: this directory already serves another port; use that
   server, `S state PORT rm`, name the real port, and restart at step 1 with it.
2. Take the dev command from the manifest. In a monorepo (`workspaces`, `turbo.json`,
   `pnpm-workspace.yaml`, `nx.json`) list the workspaces with a `dev` script, ask with
   `AskUserQuestion` when there is more than one, and launch from that app's directory.
3. Pin the port with the framework's flag (`--port`, `-p`; Vite also `--strictPort`) or `PORT`.
   When the `dev` script hardcodes a port, run its command with the number swapped and the env
   prefix kept. `package.json` stays as it is.
4. `S serve PORT --dir <app dir> -- '<dev command>'` in a foreground Bash call. It starts the
   systemd user unit `dev-up-PORT` with this shell's environment; `--mem 4G` caps its memory. After
   editing `.env` this session, prefix the command with `set -a; . ./.env; set +a;`.
5. `S wait PORT` in a foreground Bash call with `timeout: 600000`.

Done when `wait` prints `READY`. Any other verdict comes with the log tail: read it, then
[troubleshooting](references/troubleshooting.md).

## 3. Arm the watcher

Load `Monitor` and `TaskStop` in one `ToolSearch` call. Arm one Monitor: command `S watch PORT`,
description `errors on port PORT`, `timeout_ms: 1800000`. Its return reads `Monitor started (task
<id>, ...)`: `S state PORT set watcher_task=<id>`.

- Expiry: let it lapse; the hook prints the errors logged since the last prompt. Re-arm only while
  the user is testing.
- A real error: report it. A transient blip (DNS `EAI_AGAIN`, one failed external call, a
  `DeprecationWarning`): ignore it. A recurring harmless line: `S state PORT exclude '<text>'`,
  `TaskStop` the watcher, re-arm. HMR errors stay reported: after an edit they are real bugs.
- Before you or a subagent edits code this server serves, installs deps or migrates: `TaskStop` the
  watcher and `S state PORT pause`; re-arm when that round is green.

Done when `S state PORT show` prints `watcher_alive=yes`.

## 4. Open the session

1. `S ab PORT open http://localhost:PORT/`.
2. `S ab PORT get url`. On a login route (`/login`, `/auth`, `/sign-in`, `/entrar`, `/acesso`,
   `/conta`): `S show PORT`, ask the user to log in in that window, and `S hide PORT` once they
   confirm. The login travels with the switch and stays in the profile.
3. Smoke: `S ab PORT errors`, `S ab PORT console`, `S ab PORT network requests --filter /api` (or
   the app's data origin).
4. Port in the title, so the dashboard and window lists name it: `S ab PORT eval '<script>'` with
   `PORT` filled in, after every `open`:

   ```js
   (() => { const p = '[PORT] '; const fix = () => { if (!document.title.startsWith(p)) document.title = p + document.title.replace(/^\[\d+\] /, ''); }; window.__devUpTitle?.disconnect(); window.__devUpTitle = new MutationObserver(fix); window.__devUpTitle.observe(document.head ?? document.documentElement, {childList: true, subtree: true, characterData: true}); fix(); return document.title; })()
   ```

Done when `get url` is on `localhost:PORT` past any login, the smoke ran, and the title starts
with `[PORT]`.

## 5. Let the user watch or take over

- **Watch**: `S dash` starts agent-browser's dashboard once and prints its URL (default
  `http://localhost:4848`): every session streams live there with its console and network, and it
  costs no measurable RAM while nobody looks. Run it on every setup and put the URL in the handback.
- **Take over**, only when the user asks to see or touch the page: `S show PORT` reopens the
  session as a real window with cookies and storage carried over, also from a session that
  closed while idle; `S hide PORT` returns to headless. The window carries the class `agent-browser`; to keep it from taking focus, read
  [window focus](references/window-focus.md).

## 6. Hand back

`S state PORT show` prints the watcher id and whether server, watcher and browser are alive. Report
the port, the log path, the session `devup-PORT` and its mode, the dashboard URL, the watcher id,
and the smoke result.

## Restart

New code, a new `.env`, another worktree on the same port. The port stays: the login belongs to
`host:port`. `S owner PORT`; with `via=dev-up` or `mine=orphan`, `S stop PORT`. `S state PORT init`
from the directory to serve, `S preflight` in another worktree, then step 2.4 and 2.5. Re-arm the
watcher only when it is dead, then step 4.1 and 4.4.

## After setup

- Driving or debugging the app: [interacting](references/interacting.md).
- Startup trouble, a dead session, a lost login: [troubleshooting](references/troubleshooting.md).
- Back after a compaction or long subagent work: `S owner PORT` and `S state PORT show`, then
  re-run the step of each dead piece.
- Shutdown, only when the user asks: [shutdown](references/shutdown.md). Until then server,
  watcher and session stay up, and the handback says so.
