---
name: browse-up
description: >-
  Starts this project's dev server on one port as a systemd user unit, opens one tab on it in the
  user's own browser through Browse (the `browse` MCP server), and arms a log watcher. Use for
  `/browse-up [port]`, or when asked to start, restart, open or watch this project's dev server
  with Browse. Not for Claude in Chrome (dev-up) or headless testing (dev-up-agent-browser).
# argument-hint, allowed-tools and hooks are Claude Code fields, not part of the Agent Skills spec.
# Drop them before uploading this folder to claude.ai or the Skills API.
argument-hint: "[port]"
allowed-tools:
  - Bash(bash ${CLAUDE_SKILL_DIR}/scripts/dev-up.sh owner *)
  - Bash(bash ${CLAUDE_SKILL_DIR}/scripts/dev-up.sh preflight *)
  - Bash(bash ${CLAUDE_SKILL_DIR}/scripts/dev-up.sh wait *)
  - Bash(bash ${CLAUDE_SKILL_DIR}/scripts/dev-up.sh logs *)
  - Bash(bash ${CLAUDE_SKILL_DIR}/scripts/dev-up.sh watch *)
  - Bash(bash ${CLAUDE_SKILL_DIR}/scripts/dev-up.sh state *)
hooks:
  UserPromptSubmit:
    - hooks:
        - type: command
          command: 'p="$HOME/.cache/browse-up/dev-up.sh"; [ -f "$p" ] && bash "$p" unwatched; true'
---

# browse-up

One dev server on one **port**, one **tab** on that port, one **watcher** on the log. The port is
the key to all three:

- The server is the systemd user unit `dev-up-PORT`.
- The tab has the Browse id `dev-PORT`. Pass that id as `tab` to every `browse` call.
- The app URL is `http://PORT.localhost:PORT`. Use that URL in the tab and in every origin variable.
  Cookies ignore the port, so two apps on plain `localhost` overwrite each other's login. Each
  `PORT.localhost` host keeps its own cookies. `127.0.0.1` blocks Next's hot reload.

`PORT` below is the literal port number. A command such as `owner PORT` is the Bash call
`bash ${CLAUDE_SKILL_DIR}/scripts/dev-up.sh owner 3000`. Type that whole path on every call, from
the checkout this session works in. A path held in a variable or inside `eval` misses
`allowed-tools`, and a worktree session refuses it. Each command prints its verdict on the first
line.

With no argument, use the live port that `state` already records for this checkout and say so in
one line. With none recorded, ask for the port.

## Back in the middle of a run

After a compaction, a restart or long subagent work, check before you touch the tab:
`owner PORT`, `state PORT show`, and `tabs` with `action: "list"`. Re-run only the step of each
dead piece. An app session can expire while the run sits idle, so read `page.url()` before you
take a screenshot.

## 1. Who holds the port

`owner PORT` prints `FREE`, or `BUSY pid=N cwd=DIR mine=... via=... state=...`:

- `FREE` → `state PORT init`, then step 2.
- `mine=yes state=mine` → this session already set it up. Go to "Back in the middle of a run".
- `mine=yes`, any other state → this checkout already serves it. `state PORT init`, skip step 2.
- `mine=worktree` → another worktree serves different code. Ask the user: reuse it, or Restart
  from this checkout.
- `mine=orphan` → the server's directory was deleted. `stop PORT`, tell the user the pid and cwd
  it prints, then `state PORT init` and step 2.
- `mine=no` or `mine=?` → a foreign process. Leave it alone. Run `owner` on the next port up until
  one is `FREE`, serve there, and tell the user which process holds the port they asked for.

## 2. Start the server

1. Find the app directory. In a monorepo, that is the workspace whose `dev` script starts the app
   the user means. Ask with `AskUserQuestion` only when two or more fit.
2. `preflight <app dir>`. Run every `run` line. A `todo` line needs a decision.
   - `warn pinned port` → an auth or CORS origin in `.env` names a `localhost` URL. Prefix the
     dev command with each variable the line names, set to the app URL:
     `BETTER_AUTH_URL=http://PORT.localhost:PORT next dev -p PORT`. The prefix is for the host,
     so add it even when the line names the port you serve. Without it, sign-in answers 403
     `Invalid origin`.
     The log then says that OAuth is off or the issuer is not loopback → the app accepts OAuth
     only on plain `localhost`. Tell the user in one line. Username and password login still
     works.
   - `warn served` → this directory already runs a dev server on another port, and Next 16 allows
     one per folder. Use that port: `state PORT rm`, say the real port in one line, and return to
     step 1 with it.
3. Build the dev command from the manifest's `dev` script. Pin the port with the framework's flag
   (`--port`, `-p`, plus `--strictPort` for Vite) or the `PORT` variable. When the script
   hardcodes a port, run the script's own command with the number swapped and its env prefix
   kept. Leave `package.json` as it is.
4. Launch with a foreground Bash call:

   ```bash
   bash ${CLAUDE_SKILL_DIR}/scripts/dev-up.sh serve PORT --dir <app dir> -- '<dev command>'
   ```

   `serve` returns `STARTED unit=dev-up-PORT log=FILE`. The unit outlives this session's
   background-task limits, and it is capped at 4G of RAM. After you edit `.env` in this session,
   prefix the command with `set -a; . ./.env; set +a;`.
5. `wait PORT`, as a foreground Bash call with `timeout: 600000`. `READY` → step 3. Any other
   verdict prints the log tail: read it, then
   [`references/troubleshooting.md`](references/troubleshooting.md).

Every server this session starts goes through `serve` and stops through `stop PORT`, a prototype
on another port included. A `pkill -f` by name kills this shell too.

## 3. Arm the watcher

Load the deferred tools in one call:

```
ToolSearch "select:Monitor,TaskStop,mcp__browse__execute,mcp__browse__tabs,mcp__browse__status"
```

No `mcp__browse__*` tool comes back → [`references/troubleshooting.md`](references/troubleshooting.md).

Arm one Monitor: command `bash ${CLAUDE_SKILL_DIR}/scripts/dev-up.sh watch PORT`, description
`errors on port PORT`, `timeout_ms: 1800000`. Then `state PORT set watcher_task=<id from the
Monitor's return>`.

- A real error → report it. A one-off blip (DNS, one failed external call, a deprecation
  warning) → ignore it.
- A line that keeps coming and changes nothing the user sees → `state PORT exclude '<literal text
  from the line>'`, `TaskStop` the watcher, arm it again.
- The Monitor expires after 30 minutes. Let it lapse. That wake-up turn repeats the action that
  waits on the user, or the last result the user has not seen, and nothing about the watcher. The
  skill's hook prints new log errors on the user's next prompt. Arm it again only while the user
  tests in the tab.
- Before you or a subagent edits served code, installs dependencies or runs a migration:
  `TaskStop` the watcher and `state PORT pause`. Arm it again when typecheck or tests are green.

## 4. Open the tab

1. `tabs` with `action: "new"`, `id: "dev-PORT"`, `url: "http://PORT.localhost:PORT"`,
   `keepOpen: true`. The call is safe to repeat: an existing `dev-PORT` comes back as it is, with
   `existed: true` and no navigation.
   The call says that no browser is connected → `status`, pass its `nextStep` to the user, wait.
2. Smoke, one `execute` on `tab: "dev-PORT"`:

   ```js
   await pageConsole.start();
   await page.reload();
   const errors = (await pageConsole.read({ errorsOnly: true })).entries.map((e) => e.text);
   await pageConsole.stop();
   return { url: page.url(), title: await page.title(), errors };
   ```

3. The `url` ended on a login route (`/login`, `/auth`, `/sign-in`, `/entrar`, `/acesso`) →
   [`references/login.md`](references/login.md). Log in before you report anything about the page.

## 5. Hand back

Report the port, the app URL, the log path from `serve`, the tab id `dev-PORT`, the watcher id,
and the smoke result: clean, or the errors it found. Called as a proof step inside other work,
the handback is one line in that task's report.

## In the tab

The `browse` server's own instructions cover inspect, act, verify. These rules are what past runs
got wrong:

- Put dependent steps in one `execute`, and wait on a condition between them: `page.waitForURL`,
  `page.waitForSelector`, `page.waitForLoadState`. A fixed sleep after a submit acts on the old
  page.
- Click through `ref("e12")` from `snapshot()`, or `page.getByRole`. `snapshot()` stops at 80
  items: pass `{ find: "text" }` or `{ within: "selector" }` for the rest.
- Check a layout by measuring it. In one `execute`, set the viewport with `browse.emulate`, take
  `page.screenshot({ fullPage: true })`, and compare element boxes with `page.evaluate`. One
  viewport screenshot has passed a broken layout before.
- The watcher sees the server log only. Client errors stay in the browser: run the smoke script
  again when a screen looks broken or an action fails.
- The first visit to a route compiles it. Give that `page.goto` a `timeout` of 60000.
- A subagent that drives the app opens its own tab, `dev-PORT-<name>`, and closes it. It never
  stops or restarts the server.
- `tabs` or `execute` says that no tab has the id `dev-PORT` → the user took the tab back or
  closed it. Run step 4.1 again.

## Restart

For new code, a new `.env`, or another worktree on the same port. Keep the port: the login cookie
belongs to `PORT.localhost`.

1. `owner PORT`. `via=dev-up` or `mine=orphan` → `stop PORT`. `via=other` → leave it running,
   serve on the next `FREE` port and tell the user the real port.
2. `state PORT init` from the directory you will serve. For another worktree, `preflight` there.
3. Launch and wait as in steps 2.4 and 2.5.
4. Arm the watcher only when `state PORT show` says `watcher_alive=no`. Reload the tab:
   `await page.goto("http://PORT.localhost:PORT")` on `tab: "dev-PORT"`.

## Shutting down

Server, watcher and tab stay up until the user asks for a shutdown. Then follow
[`references/shutdown.md`](references/shutdown.md).
