---
name: dev-up
description: >-
  Starts a project's dev server pinned to one port, opens a browser tab you own on it, and arms a
  watcher on its log so you can hand control back and walk away. Use when invoking `/dev-up [port]`,
  or when asked to start, open, view, run, serve, or monitor this project's dev server on a specific
  port — especially when other servers or browser tabs are already running in parallel and must not
  be disturbed. Not for an Expo app on a phone or emulator, that is mobile-up.
# argument-hint is Claude Code-specific, not part of the Agent Skills spec — drop this field before
# uploading this skill folder to claude.ai or the Skills API.
argument-hint: "[port]"
---

# dev-up

Pins one dev server to one **port**, opens one browser **tab** you own at that port, and arms a
**watcher** on the log — so you can hand control back and walk away. The port is the source of
truth: the server binds it, the tab navigates to it, the watcher follows it.

Each Claude Code session now gets its **own** `claude-in-chrome` tab group (the extension scopes
groups per session), so you no longer share one with other instances — but you can still collect
**several `localhost` tabs inside your own group** (ran `dev-up` twice, dragged a tab in), and the
shutdown last-tab hazard is real. That one-tab discipline, and what changed about group sharing,
live in [`references/coexistence.md`](references/coexistence.md) — read it the moment step 4 shows
**other `localhost` tabs already in the group**.

First time on this machine (extension not installed, or no browser connected)? Step 4 detects it and
walks you through the one-time setup — see [`references/setup.md`](references/setup.md). No separate
command to remember.

## Invocation

`/dev-up [port]`. With no argument, ask for the port — **unless the folder has no dev server at
all** (no manifest, or a manifest with no `dev` script): inspect first, and if there's nothing to
run, say so instead of asking for a port for a server that doesn't exist.

Two habits throughout: **inspect before asking** (offer options built from real data — apps,
browsers — never in the abstract), and **investigate, don't assume** (stack-agnostic: learn how
the project runs by reading its files, not by guessing).

**`PORT` is a placeholder** for the actual port number, substituted literally into every command
and env var below — it is never a shell variable named `PORT` unless the app itself reads an env
var by that name.

## Flow

### 1. Is the port already in use, and by whom?

```bash
if command -v ss >/dev/null 2>&1; then
  LISTEN_LINE=$(ss -ltnp "sport = :PORT" 2>/dev/null | grep LISTEN)
elif command -v lsof >/dev/null 2>&1; then
  LISTEN_LINE=$(lsof -nP -iTCP:PORT -sTCP:LISTEN 2>/dev/null)
else
  echo "Neither ss nor lsof exists on this machine — can't check the port. Stop and tell the user."
fi
if [ -n "$LISTEN_LINE" ]; then
  PID=$(echo "$LISTEN_LINE" | grep -oE '[0-9]+' | tail -1)
  echo "BUSY pid=$PID cwd=$(readlink -f /proc/$PID/cwd 2>/dev/null)"
else
  echo "FREE"
fi
```

`ss` (part of `iproute2`) checks who's *listening* — `curl` would report a false "free" when the
root answers 404/500. It doesn't exist on macOS/BSD; fall back to `lsof -nP -iTCP:PORT
-sTCP:LISTEN`, and if neither binary is on the machine, say so and stop instead of guessing FREE.

Busy doesn't mean *your* server. Compare the listener's `cwd` against this checkout (or a worktree
of it) before reusing it — the same "reuse by owner, never by number" rule
`mobile-up/references/coexistence.md:6-9` applies, because the common collision is another checkout
of the *same* project, not an unrelated one.

**Free** → start it (step 2). **Busy, `cwd` under this checkout** → already running; skip step 2's
launch, go to step 3 (still arm the watcher — see step 3 for creating its log first if a prior
`dev-up` didn't). **Busy, `cwd` elsewhere** → a foreign process; leave it alone, don't reuse or kill
it, and ask the user how to proceed.

### 2. Start the server

0. **Preflight deps in a worktree.** A fresh worktree (`~/.herdr/worktrees/…`, `git worktree`) has
   no `node_modules`/`.venv`: check before launching (`[ -d node_modules ] || [ -d .venv ]`), and if
   missing, symlink from the main checkout (`ln -s <main>/node_modules node_modules`, same for
   `.venv` and per-app `apps/*/node_modules`) or install with the lockfile's manager. Two audited
   runs burned a launch + log read on `esbuild: command not found` for lack of this step.
1. **Find the dev command.** Read the manifest. In a **monorepo** (`workspaces`, `turbo.json`,
   `pnpm-workspace.yaml`, `nx.json`) the root `dev` starts *every* app — list the workspaces with a
   `dev` script; more than one → `AskUserQuestion`, one option per workspace; work in that app's dir.
2. **Override the port.** Command already pins one (`--port N`, `-p N`, `PORT=N`) → swap the
   number for `PORT`. Doesn't → add the framework's flag (`<bin> --help`, or the `find-docs` skill if installed;
   fallback: export the app's own `PORT` env var directly, e.g. `PORT=<the number> <bin> dev`).
   Force the exact port where the framework allows (e.g. Vite
   `--strictPort`) so it can't auto-increment onto a neighbour. **Before settling on a port other
   than the app's usual one**, grep env/config for a hardcoded `localhost:<port>` (auth callbacks,
   CORS, OAuth redirects): if it's pinned, a different port silently breaks login/CORS — **warn in
   one line and keep going on the port the user asked for; don't re-ask it.** See
   [`references/troubleshooting.md`](references/troubleshooting.md).
3. **Run it in the background** (`run_in_background: true`), with a dedicated log. Launch through
   the package manager the lockfile names — `bun.lockb`/`bun.lock` → `bun run dev`,
   `pnpm-lock.yaml` → `pnpm run dev`, `yarn.lock` → `yarn dev`, `package-lock.json` → `npm run dev`
   — since a monorepo with hoisted deps (npm/yarn workspaces, pnpm without `shamefully-hoist`, bun
   workspaces — the exact case step 1 just described) has no per-app `./node_modules/.bin/<bin>` to
   call. Fall back to `./node_modules/.bin/<bin>` only when there's no lockfile-managed script:

   ```bash
   mkdir -p ~/.cache/dev-up && cd apps/<app> && bun run dev --port PORT > ~/.cache/dev-up/PORT.log 2>&1
   ```

   Background is load-bearing twice: it frees the shell, **and** the harness re-invokes you when
   the task exits — so the server dying is caught for free, no port-polling needed. If you edited
   env (`.env`/config) this session, source it in the launch command
   (`set -a; . ./.env; set +a; <bin> dev ...`) — a background child inherits the launching shell's
   env, which a version manager may have seeded with stale values, not your edit.
4. **Wait for the TCP bind in a blocking (foreground) Bash.** **Foreground only — never
   `run_in_background` on *this* call.** Backgrounded, the loop returns a task id instead of
   blocking, so you move on before any listener exists, then patch over it with manual polls or a
   second loop:

   ```bash
   is_bound() {
     if command -v ss >/dev/null 2>&1; then
       ss -ltn "sport = :PORT" 2>/dev/null | grep -q LISTEN
     else
       lsof -nP -iTCP:PORT -sTCP:LISTEN >/dev/null 2>&1
     fi
   }
   i=0
   while ! is_bound; do
     i=$((i+1))
     if [ $i -ge 40 ]; then
       grep -qi compiling ~/.cache/dev-up/PORT.log 2>/dev/null && i=0 || break
     fi
     sleep 0.5
   done
   ```

   Same `ss`/`lsof` fallback as step 1, inline this time since the loop runs unattended. The loop is bounded to ~20s of
   silence, but resets its own counter while the log still says "compiling" — a first, uncached
   build can take far longer, and this is what lets it keep waiting without hanging forever. Give
   this Bash call an explicit high `timeout` (up to 600000ms) as the hard backstop: at the default
   timeout the harness doesn't fail the loop — it silently auto-backgrounds it, which breaks the
   very blocking guarantee this step exists for. Exits with no bind: read the log and report.
   **Bind ≠ ready** for a slow stack (Python/Flask can take
   15–40s to *serve* after the socket binds): there, a foreground HTTP-readiness poll
   (`curl -s -o /dev/null --retry 60 --retry-connrefused --retry-delay 1 http://localhost:PORT`)
   waits for the app to actually answer, not just bind. A **missing-module / dependency error**, or
   "another server is already running" despite a FREE port → see
   [`references/troubleshooting.md`](references/troubleshooting.md).

### 3. Arm the watcher — the moment the port binds

Do this **before** the tab. This step is what the rest of the skill is accountable for while you're
away, and arming it now, while you're still watching the terminal, is what keeps it from being
forgotten during handback.

**Load the deferred tools you'll need now, in one `ToolSearch`** — `Monitor`, `PushNotification`,
`TaskStop`, and the `claude-in-chrome` set (`list_connected_browsers`, `select_browser`,
`switch_browser`, `tabs_context_mcp`, `tabs_create_mcp`, `navigate`, `read_page`,
`read_console_messages`, `read_network_requests`, `browser_batch`, `tabs_close_mcp`). The
console/network pair plus `browser_batch` are for step 4's smoke-check and `tabs_close_mcp` for
shutdown; every run needs all of them, and a second `ToolSearch` later for one you skipped is a
wasted round-trip.

Create the log first if the Busy path skipped step 2 (`tail -f` on a missing file exits
immediately, and a dead watcher then falsely reports itself as armed):

```bash
mkdir -p ~/.cache/dev-up && [ -f ~/.cache/dev-up/PORT.log ] || : > ~/.cache/dev-up/PORT.log
```

One Monitor, persistent, filtering the log for trouble:

```bash
tail -n 0 -f ~/.cache/dev-up/PORT.log | grep -E --line-buffered \
  "[Ee]rror|Exception|Traceback|Failed to compile|unhandled|ECONNREFUSED|EADDRINUSE|panic|FATAL" \
  | grep -v --line-buffered -E "NEXT_REDIRECT|PoolError|QueuePool limit|Too many connections"
```

(`NEXT_REDIRECT` is Next.js's internal redirect signal, not an error: a documented false positive
that pushed duplicate alerts in a real run, hence the exclusion. `PoolError`/`QueuePool limit` is
the DB pool saturating under an E2E burst: benign, and it woke the controller 7 times in one
audited session, each wake a full turn.

Classify a runtime error as benign only when all three hold: it recurs rather than being a one-off,
it doesn't change the app's observable behavior, and reporting it wouldn't give the user anything
to act on. When one meets those, handle it on the spot: `TaskStop` the running Monitor, re-arm it
with the pattern added to the exclusion filter, and append it to the `.state` file's `excluded`
field (step 5) so a restored session keeps the same filter instead of re-litigating an alert it
already dismissed.)

`description: "errors on port PORT"`, **`persistent: true`**: this keeps the watcher alive for the
whole session. With it set, `timeout_ms` is required by the tool but has no effect on a persistent
watcher, so don't spend time tuning it. `tail -n 0` = new lines
only. **No port-polling here** — the
server's death already re-invokes you via step 2's background task; the Monitor only catches errors
while it's alive. (Reused a server you didn't start? Its death won't auto-signal — re-check the
port when you return, or add the port-poll fallback in
[`references/troubleshooting.md`](references/troubleshooting.md).)

**Triage before you push.** A real error → `PushNotification`. A transient infra hiccup (DNS
`EAI_AGAIN`, an external-service blip, a `DeprecationWarning`) isn't actionable — don't push. Log
flooding with *expected* errors during a schema migration → `TaskStop` the watcher until it
stabilises instead of spamming.

### 4. Connect and pin the tab

1. **Select the browser.** `list_connected_browsers`.
   - **None connected, or the call errors** → the extension isn't set up on this machine yet. This is
     the one-time bootstrap: follow [`references/setup.md`](references/setup.md) to install/pair it,
     then re-run `list_connected_browsers` and continue. Don't ask the user to run a separate setup
     command — there isn't one; you do the setup here.
   - **One connected** → use it directly; the round-trip isn't worth a question.
   - **Two or more** → **read the remembered choice first — every time, before any `AskUserQuestion`.**
     Reaching for `AskUserQuestion` before you've read the cache is the bug: it re-asks a browser the
     user already picked. This machine caches its preferred browser at
     `${XDG_CONFIG_HOME:-$HOME/.config}/dev-up/browser`, **two lines**:

     ```
     deviceId=<the device's deviceId>
     name=<the device's display name>
     ```

     **Match if a connected device's `deviceId` OR `name` equals the saved value.** Both fields are
     checked because which one stays stable across sessions varies by extension/setup — see
     [`references/browser-cache.md`](references/browser-cache.md) for why, and for the legacy
     one-line cache format.
     - **Hit** — a connected device matches on deviceId or name → `select_browser` with that
       device's current deviceId. **Don't ask**: the user already chose, when the browser was first
       bound. (The extension keeps its own approval modes and can still show a native prompt on a
       hit; that's not a cache failure — details in
       [`references/browser-cache.md`](references/browser-cache.md).)
     - **Miss** — file absent, or neither the saved deviceId nor name is among the connected devices →
       `AskUserQuestion` listing every browser (name + deviceId), recommending the device marked on
       this computer (`localhost:PORT` only resolves where the server runs). Persist both fields
       after picking — writing only the name breaks the next run's match:

       ```bash
       D="${XDG_CONFIG_HOME:-$HOME/.config}/dev-up"; mkdir -p "$D"
       printf 'deviceId=%s\nname=%s\n' "<chosen deviceId>" "<chosen name>" > "$D/browser"
       ```

     Wrong browser later, or want to re-pick? `rm ~/.config/dev-up/browser` and it asks again.
     (Multiple connected browsers just means multiple devices to choose between — **not** a shared
     group; each session has its own. See [`references/coexistence.md`](references/coexistence.md).)
2. **Find or create the tab.** `tabs_context_mcp` (`createIfEmpty: true`): reuse an existing tab on
   `localhost:PORT`, else `tabs_create_mcp`. **Never call `browser_batch` on a tab still at
   `about:blank`/`chrome://newtab`** — the MCP refuses browser-internal URLs (`Can't interact with
   browser-internal or unparseable URLs`; 4 audited sessions hit this). Order: `navigate` to
   **`http://localhost:PORT` — the root, not a deep route** (try `https://` if it won't load);
   then **arm the console/network tracking**: one throwaway `browser_batch` of
   `read_console_messages` + `read_network_requests` on the tab — both tools only start recording
   at their first call, so a reading taken before arming is structurally empty (10 of 15 audited
   runs hit this and burned a re-navigate); then `navigate` to the root once more so the boot is
   recorded. Root surfaces any login redirect
   whatever route the app lands on, so you catch auth before going deeper; navigating straight to a
   protected sub-path on first load can 307 into a Chrome error page that then blocks every
   `claude-in-chrome` call. Once the root's confirmed, navigate on to the route you actually need.
   If the context shows **other `localhost:<port>` tabs** already in your group (you, earlier — not
   another instance) → [`references/coexistence.md`](references/coexistence.md).
   (`createIfEmpty: true` counts as a state-changing flag — under plan/Manual mode this call may
   prompt for approval; that's expected, not an error to retry.)
3. **Record the `tab_id` as `TARGET_TAB_ID`** — the one tab you own.
4. **Confirm the final URL — don't trust `navigate`'s return** (it sometimes reports the old
   `chrome://newtab/` before the nav settles). Re-check with `tabs_context_mcp` — it already
   carries the tab's URL, far cheaper than `read_page`'s full accessibility tree; fall back to
   `read_page` only if it's inconclusive. **Never a screenshot to confirm a URL.** `cic:computer` is the wrong tool here: viewport-only, it
   returns no URL text and times out (~30s) while the renderer compiles a first-visit route. If it
   redirected to login (`/login`, `/auth`, `/sign-in`, `/entrar`, `/acesso`, `/conta` …), **stop and
   ask the user to log in** — you never enter credentials; continue once they confirm. (URL
   unchanged but the screen differs → a client-side hydration redirect, not auth; treat as loaded.)
5. **Smoke-check the client — once, before handback.** The watcher (step 3) only sees the
   **server** log; a client-side boot failure — a thrown render, a `fetch` 4xx/5xx, a failed JS
   chunk — never reaches stdout, so **nothing alerts you later**. With the route settled, read the
   browser side **once** on `TARGET_TAB_ID`, both calls in one `browser_batch` (two known read-only
   reads with no output→input dependency — the exact case for batching; the tracking has been
   recording since you armed it in step 4.2): `read_console_messages`
   (`onlyErrors: true`, `pattern: "error|failed|exception"`) and `read_network_requests`
   (`urlPattern: "/api"`, or the app's data origin). Clean → say so in the handback. A real boot
   error → fold it into the handback (and `PushNotification` if you've already walked away); a lone
   transient (one aborted HMR fetch, a third-party blip) isn't actionable — don't push on it. This
   is a **one-shot snapshot, not a watcher** — the console can't be tailed in the background.
   `read_console_messages` only requires a `tabId`; `pattern` is a recommendation that narrows the
   read, not a requirement. Re-run it on demand later
   ([`references/interacting.md`](references/interacting.md)).

### 5. Hand control back

1. **Gate on the watcher.** Its proof is the Monitor's own start return — a task id plus
   *"persistent — runs until TaskStop or session end"*. Got it → the watcher's live. Errored or no
   task id → re-arm it before reporting anything.
2. **Don't reach for `TaskList` to check.** A Monitor is a background process and never appears
   there, so `TaskList` always says "No tasks found" — that's not a failed gate, don't let it tempt
   you into skipping step 1.
3. **Persist the contract** for future turns:

   ```bash
   mkdir -p ~/.cache/dev-up
   printf 'port=%s\nserver_task=%s\nwatcher_task=%s\ntab_id=%s\nowner=%s\nexcluded=%s\n' \
     PORT "$SERVER_TASK" "$WATCHER_TASK" "$TARGET_TAB_ID" "$OWNER" "$EXCLUDED" \
     > ~/.cache/dev-up/PORT.state
   ```

   `owner` is `self` if step 1 was FREE and you launched the server, `reused` if it was BUSY and
   you didn't — shutdown step 1 reads it. `excluded` is the pipe-joined list of patterns step 3
   taught the watcher to ignore. After a session restart, a context compaction, or long subagent
   work, this file is how you restore the whole package (server, watcher, tab), not just re-check
   the port — see [`references/troubleshooting.md`](references/troubleshooting.md).
4. **Report:** port, log path, `TARGET_TAB_ID`, Monitor task id, and the client smoke-check result
   (clean, or the boot error step 4 surfaced). Stop.

## After setup

- **Driving or debugging the app** through `TARGET_TAB_ID` (clicks, forms, reading the console) →
  [`references/interacting.md`](references/interacting.md).
- **Something's off at startup** (env not taking effect, hardcoded base URL, deps, port respawns)
  → [`references/troubleshooting.md`](references/troubleshooting.md).
- **Coexisting with other tabs/instances** → [`references/coexistence.md`](references/coexistence.md).

## Shutting down

When the task is done, `AskUserQuestion` on whether to shut down, recommending "keep it running" —
closing something the user didn't ask you to close is the costlier mistake. (Running autonomously
with no one to answer? Assume shutdown once the task is done and say so in the handback, don't skip
the gate silently.) If yes, in order:

1. **Read `owner` from the `.state` file first.** `owner=reused` means step 1 found this server
   already running and you never started it: skip steps 2 and 4 below, the server itself and its
   port stay alive. Only `owner=self` clears you to stop the server and free the port. Steps 3 and
   5 (watcher, tab) run either way, they're yours regardless of who owns the server.
2. **`owner=self` only.** `TaskStop` the server's background task (just killing the PID lets a
   supervisor respawn it).
3. `TaskStop` the watcher.
4. **`owner=self` only.** `fuser -k PORT/tcp` — kills exactly who holds the listening socket
   (`lsof -ti tcp:PORT | xargs kill` would also catch the browser attached to the port). If the
   port keeps coming back, an external supervisor is respawning it: tell the user, don't kill
   blindly.
5. **Close only `TARGET_TAB_ID`** with `tabs_close_mcp` — never the group itself, never a tab you
   didn't open. Match by the recorded id's value against the live `tabs_context_mcp` list, never by
   which tab looks like yours: a recorded id can be silently reused for another URL (a real
   shutdown closed the wrong tab this way). A "tab group no longer exists" reply is an inconclusive
   state to note in the handback, not proof the environment is clean. If yours might be the last
   tab in the group, closing it can collapse the whole group; the last-tab hazard and the rest of
   the group rules are in [`references/coexistence.md`](references/coexistence.md). Then remove the
   log and `~/.cache/dev-up/PORT.state`.
