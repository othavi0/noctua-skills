---
name: dev-up
description: |
  Use when invoking `/dev-up <port>`, or when asked to start, open, view, run, serve, or monitor
  this project's dev server on a specific port — especially when other servers or browser tabs are
  already running in parallel and must not be disturbed. Pins one dev server to one port, opens a
  single browser tab you own at that port, and arms an error watcher before handing control back.
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

`/dev-up <port>`. With no argument, ask for the port — **unless the folder has no dev server at
all** (no manifest, or a manifest with no `dev` script): inspect first, and if there's nothing to
run, say so instead of asking for a port for a server that doesn't exist.

Two habits throughout: **inspect before asking** (offer options built from real data — apps,
browsers — never in the abstract), and **investigate, don't assume** (stack-agnostic: learn how
the project runs by reading its files, not by guessing).

## Flow

### 1. Is the port already in use?

```bash
ss -ltn "sport = :PORT" | grep -q LISTEN && echo BUSY || echo FREE
```

`ss` checks who's *listening* — `curl` would report a false "free" when the root answers 404/500.
**Free** → start it (step 2). **Busy** → it's already running; skip step 2's launch, go to step 3
(still arm the watcher — on `/tmp/dev-up-PORT.log` if a prior `dev-up` created it).

### 2. Start the server

1. **Find the dev command.** Read the manifest. In a **monorepo** (`workspaces`, `turbo.json`,
   `pnpm-workspace.yaml`, `nx.json`) the root `dev` starts *every* app — list the workspaces with
   a `dev` script, ask which if there's more than one, and work in that app's dir.
2. **Override the port.** Command already pins one (`--port N`, `-p N`, `PORT=N`) → swap the
   number for `PORT`. Doesn't → add the framework's flag (`<bin> --help` or `find-docs` if unsure;
   fallback `PORT=PORT`). Force the exact port where the framework allows (e.g. Vite
   `--strictPort`) so it can't auto-increment onto a neighbour. **Before settling on a port other
   than the app's usual one**, grep env/config for a hardcoded `localhost:<port>` (auth callbacks,
   CORS, OAuth redirects): if it's pinned, a different port silently breaks login/CORS — **warn in
   one line and keep going on the port the user asked for; don't re-ask it.** See
   [`references/troubleshooting.md`](references/troubleshooting.md).
3. **Run it in the background** (`run_in_background: true`), with a dedicated log:

   ```bash
   cd apps/<app> && ./node_modules/.bin/<bin> dev --port PORT > /tmp/dev-up-PORT.log 2>&1
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
   until ss -ltn "sport = :PORT" | grep -q LISTEN; do sleep 0.5; done
   ```

   ~20s with no bind → read the log and report. (A first, uncached build can take far longer — if
   the log says "compiling", keep waiting.) **Bind ≠ ready** for a slow stack (Python/Flask can take
   15–40s to *serve* after the socket binds): there, a foreground HTTP-readiness poll
   (`curl -s -o /dev/null --retry 60 --retry-connrefused --retry-delay 1 http://localhost:PORT`)
   waits for the app to actually answer, not just bind. A **missing-module / dependency error**, or
   "another server is already running" despite a FREE port → see
   [`references/troubleshooting.md`](references/troubleshooting.md).

### 3. Arm the watcher — the moment the port binds

Do this **before** the tab. It's the skill's **contract** — what earns its keep while you're away
— and arming it here, attention still on the terminal, is what stops it slipping through the
handback.

**Load the deferred tools you'll need now, in one `ToolSearch`** — `Monitor`, `PushNotification`,
`TaskStop`, and the `claude-in-chrome` set (`list_connected_browsers`, `select_browser`,
`switch_browser`, `tabs_context_mcp`, `tabs_create_mcp`, `navigate`, `read_page`,
`read_console_messages`, `read_network_requests`). The last two are for step 4's smoke-check; every
run needs all of them, and a second `ToolSearch` later for one you skipped is a wasted round-trip.

One Monitor, persistent, filtering the log for trouble:

```bash
tail -n 0 -f /tmp/dev-up-PORT.log | grep -E --line-buffered \
  "[Ee]rror|Exception|Traceback|[Ww]arn|Failed to compile|unhandled|ECONNREFUSED|EADDRINUSE|panic|FATAL"
```

`description: "errors on port PORT"`, **`persistent: true`** — that flag is the whole safety: it
keeps the watcher alive for the entire session, and with it set the Monitor's `timeout_ms` is
ignored (the tool requires the field, but it has no effect, so don't waste thought tuning it; a
value like `300000` does *not* stop the watcher when `persistent` is true). `tail -n 0` = new lines
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

     **Match if a connected device's `deviceId` OR `name` equals the saved value** — store and check
     both, because *which one is stable depends on the extension/setup*: in some, the deviceId is
     regenerated each session (so name is the stable key); in others (observed in practice), the
     **deviceId stays constant for weeks while the name churns** (a named device silently reverts to
     a generic `"Browser 1/2/3"`, and a name set via `switch_browser` may never appear in
     `list_connected_browsers`). Checking either field survives both. (Legacy cache = a single bare
     line with no `=`? Treat it as `name=` and match by name only; rewrite it to the two-line form on
     the next miss.)
     - **Hit** — a connected device matches on deviceId or name → `select_browser` with *that
       device's current deviceId*. **Don't ask.** `list_connected_browsers`'s output ends with a
       hard "you MUST call AskUserQuestion … do not pick one yourself" — that is the *no-cache*
       instruction and does **not** apply on a hit: the user already chose, when the browser was first bound.
       Selecting straight through is the whole point: choose once, then never again.
     - **Miss** — file absent, or neither the saved deviceId nor name is among the connected devices →
       `AskUserQuestion` listing every browser (name + deviceId), recommending the device marked on
       this computer (`localhost:PORT` only resolves where the server runs). Names may all be generic
       (`"Browser 1/2/3"`) — then the deviceId is the only thing that tells them apart; lean on it.
       Optionally `switch_browser` so the user can name it, but **don't rely on that name sticking** —
       the deviceId is what you cache as the durable key. **`switch_browser` does not return a
       `deviceId`**, so after `select_browser` call `list_connected_browsers` once more and copy the
       exact `deviceId` from there. Persist **both** fields, read verbatim — writing only the name
       (the legacy one-line form) guarantees a miss on every later run:

       ```bash
       D="${XDG_CONFIG_HOME:-$HOME/.config}/dev-up"; mkdir -p "$D"
       printf 'deviceId=%s\nname=%s\n' "<chosen deviceId>" "<chosen name>" > "$D/browser"
       ```

     Wrong browser later, or want to re-pick? `rm ~/.config/dev-up/browser` and it asks again.
     (Multiple connected browsers just means multiple devices to choose between — **not** a shared
     group; each session has its own. See [`references/coexistence.md`](references/coexistence.md).)
2. **Find or create the tab.** `tabs_context_mcp` (`createIfEmpty: true`): reuse an existing tab on
   `localhost:PORT`, else `tabs_create_mcp`, then `navigate` to **`http://localhost:PORT` — the
   root, not a deep route** (try `https://` if it won't load). Root surfaces any login redirect
   whatever route the app lands on, so you catch auth before going deeper; navigating straight to a
   protected sub-path on first load can 307 into a Chrome error page that then blocks every
   `claude-in-chrome` call. Once the root's confirmed, navigate on to the route you actually need.
   If the context shows **other `localhost:<port>` tabs** already in your group (you, earlier — not
   another instance) → [`references/coexistence.md`](references/coexistence.md).
3. **Record the `tab_id` as `TARGET_TAB_ID`** — the one tab you own.
4. **Confirm the final URL — don't trust `navigate`'s return** (it sometimes reports the old
   `chrome://newtab/` before the nav settles). Re-check with `tabs_context_mcp` or `read_page` —
   **never a screenshot to confirm a URL.** `cic:computer` is the wrong tool here: viewport-only, it
   returns no URL text and times out (~30s) while the renderer compiles a first-visit route. If it
   redirected to login (`/login`, `/auth`, `/sign-in`, `/entrar`, `/acesso`, `/conta` …), **stop and
   ask the user to log in** — you never enter credentials; continue once they confirm. (URL
   unchanged but the screen differs → a client-side hydration redirect, not auth; treat as loaded.)
5. **Smoke-check the client — once, before handback.** The watcher (step 3) only sees the
   **server** log; a client-side boot failure — a thrown render, a `fetch` 4xx/5xx, a failed JS
   chunk — never reaches stdout, so **nothing alerts you later**. With the route settled, read the
   browser side **once** on `TARGET_TAB_ID`: `read_console_messages`
   (`onlyErrors: true`, `pattern: "error|failed|exception"`) and `read_network_requests`
   (`urlPattern: "/api"`, or the app's data origin). Clean → say so in the handback. A real boot
   error → fold it into the handback (and `PushNotification` if you've already walked away); a lone
   transient (one aborted HMR fetch, a third-party blip) isn't actionable — don't push on it. This
   is a **one-shot snapshot, not a watcher** — the console can't be tailed in the background, so
   `read_console_messages` requires a `pattern` and you re-run it on demand later
   ([`references/interacting.md`](references/interacting.md)).

### 5. Hand control back

Gate first: the watcher is the contract, and its proof is **the Monitor's own start return** — a
task id plus *"persistent — runs until TaskStop or session end"*. That return **is** the gate: got
it, the watcher's live; errored or no task id, re-arm before reporting. **Don't reach for `TaskList`
to check** — a Monitor is a background process and never appears there, so `TaskList` always says
"No tasks found" and the gate looks falsely failed (which only tempts you to skip it). Then report:
port, log path, `TARGET_TAB_ID`, Monitor task id, and the **client smoke-check result** (clean, or
the boot error step 4 surfaced). Stop.

## After setup

- **Driving or debugging the app** through `TARGET_TAB_ID` (clicks, forms, reading the console) →
  [`references/interacting.md`](references/interacting.md).
- **Something's off at startup** (env not taking effect, hardcoded base URL, deps, port respawns)
  → [`references/troubleshooting.md`](references/troubleshooting.md).
- **Coexisting with other tabs/instances** → [`references/coexistence.md`](references/coexistence.md).

## Shutting down

When the task is done, **ask whether to shut down**. If yes, in order:

1. `TaskStop` the server's background task (just killing the PID lets a supervisor respawn it).
2. `TaskStop` the watcher.
3. `fuser -k PORT/tcp` — kills exactly who holds the listening socket (`lsof -ti tcp:PORT | xargs
   kill` would also catch the **browser** attached to the port). If the port keeps coming back,
   an external supervisor is respawning it — tell the user, don't kill blindly.
4. **Close only `TARGET_TAB_ID`** with `tabs_close_mcp` — never the shared group, never a tab you
   didn't open. ⚠️ If yours might be the *last* tab in the group, closing it can collapse the whole
   group; the last-tab hazard and the rest of the shared-group rules are in
   [`references/coexistence.md`](references/coexistence.md). Then remove the log.
