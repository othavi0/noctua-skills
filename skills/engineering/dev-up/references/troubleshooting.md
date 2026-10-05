# Troubleshooting — startup gotchas

Stack-agnostic edge cases seen in practice. Reach here from [`SKILL.md`](../SKILL.md) step 2 when
startup misbehaves.

## Won't bind / errors on launch

- **Missing-module / dependency error.** The deps aren't installed, or a branch added packages
  that the main checkout lacks. Rerun `preflight` and run its `run` line. A `node_modules`
  symlinked from another checkout breaks Turbopack (`FATAL`, "points out of the filesystem root")
  and serves the main checkout's workspace packages: delete the symlink and install.
- **`ModuleNotFoundError` in a Python app that has a `.venv`.** The launch ran the `python` a
  version manager put on `PATH`. Launch through `serve`, which puts `.venv/bin` first.
- **"Another server is already running" despite a FREE port.** Some dev servers (e.g. recent Next)
  allow only *one* instance per directory, regardless of port — there's another instance in the
  same dir on another port. Offer to reuse it or take it down (with confirmation); don't force it.
- **The port keeps coming back after you kill it.** An external supervisor (a `turbo dev`/`bun
  dev` in a terminal, a process manager) is respawning it. Don't kill blindly — tell the user.

## Runs, but behaves wrong

- **Login vanishes after a port change.** The session cookie belongs to `host:port`. To prove
  another worktree, use Restart on the same port instead of a second port.
- **OAuth returns to the production domain** (a Supabase Site URL, a Google redirect URI). Copy the
  `?code=...` from that URL onto `http://localhost:PORT/<callback route>?code=...` in the same tab.
  The code works once and expires in minutes.
- **An edited CSS file changes nothing in the tab.** A Tailwind `--watch` inside the dev script can
  stop without logging an error. Compare the mtime of the generated CSS with the source before you
  trust a measurement.

- **An edited `.env`/config doesn't take effect.** A running server won't pick up env changes, and
  a server you launched in the background inherits the *launching shell's* env — which a version
  manager (mise/asdf/direnv) may have seeded at boot with stale values. Source it in the launch
  command (`set -a; . ./.env; set +a; …`) or relaunch from a fresh shell. Don't trust an edit
  alone.
- **The app hardcodes its base URL/port.** Auth callbacks, CORS origins, OAuth redirect URIs and
  cookie domains are often pinned to a specific `http://localhost:<port>` in env/config. Run on a
  *different* port than they expect and login (often a silent bounce to `/login`), CORS, or cookies
  break. Grep the config/env for the port before switching; if it's pinned, **emit a one-line inline
  warning and keep going on the port the user asked for** — e.g. "Note: `BETTER_AUTH_URL` is pinned
  to :3001, so login/CORS may break on :PORT." **Don't turn this into an `AskUserQuestion`** that
  re-asks a port they already gave — that's a wasted round-trip, not a real choice. (Only when *you*
  pick the port — they gave none — prefer the pinned one and say why in a line.)

## `wait` verdicts

- `DIED`: the process `serve` started is gone. The log tail says why.
- `HTTP_5XX`: the server runs but its root throws. Fix the error in the log before the tab.
- `BUSY_OTHER pid=N`: another process holds the port, so this `serve` could not bind. Run `owner`.
- `BOUND_NO_HTTP`: something listens but does not speak HTTP on `/`. Check the dev command's port.
- `TIMEOUT`: nothing bound within 9 minutes while the process stayed alive.

## The server task ended with no error in the log

The background task of `serve` exits when the server dies, and the harness tells you. Read the
reason before relaunching:

- "low on memory", or `Killed` with nothing in the log: the OOM killer or systemd-oomd. Relaunch
  through Restart with `serve --mem 4G` so the cap applies to the server alone.
- `SIGTERM` while a subagent was working: a delegate killed it by name. Tell delegates that start
  servers to free only their own port with `fuser -k <port>/tcp`, never `pkill -f`.
- Relaunch only through `serve` in a background task. `nohup`, `setsid` and `disown` detach the
  server, and its next death reaches no one.

## The browser tab shows a Chrome "error page" / `claude-in-chrome` calls fail

A `claude-in-chrome` call returning "Frame … is showing error page", or `read_page`/`computer`
failing, means the **tab** is wedged — not necessarily the server. Localise the fault before
retrying:

- **Curl the server directly:** `curl -s -o /dev/null -w "status=%{http_code}\n" http://localhost:PORT`.
  A 200/307 means the server's healthy and the tab/CDP is the problem (a 307 → `/login` is just the
  unauthenticated bounce — curl carries no cookie — not an error).
- **After a server restart**, the CDP attach to the old tab often breaks (every call errors). Don't
  loop screenshots — open a fresh tab via `tabs_context_mcp`/`tabs_create_mcp` or re-`navigate`, then
  re-confirm the URL.
- **Stop after ~2 failed `claude-in-chrome` calls** on the same tab and switch to curl + log reads;
  hammering a wedged tab just burns calls (one real run spent six screenshots on a dead CDP link
  before checking the server, which was fine all along).
- **Calls hang with no clear error at all** (no "Frame … showing error page", no CDP timeout) —
  suspect a native JS dialog (`alert`/`confirm`/`prompt`, often a `beforeunload` or a delete
  confirm) open in some tab of the group: dialogs block browser events and Claude stops receiving
  commands, while curl still returns 200. No MCP call can close a native dialog — ask the user to
  dismiss it manually, then retry; only after that try a fresh tab or reconnecting the extension.
- **Every call fails with "Receiving end does not exist"** after the session sat idle — the
  extension's service worker went idle and dropped the connection (dev-up's exact usage pattern:
  watcher armed, user walks away, comes back later). It's not the tab nor the server: run
  `/chrome` and pick **Reconnect extension**, then resume on the same `TARGET_TAB_ID`.

## Watcher blocked by "auto mode cannot determine the safety…"

The permission classifier can be temporarily unavailable, failing `Monitor` (or `Bash`) with that
message. It's an infra hiccup, not a denial: retry the Monitor within the next few actions — not
only at the end of the cycle — and say in one line that you're temporarily running without a
watcher. A `Bash` blocked the same way twice in a row → ask the user to run it with the `!` prefix
instead of retrying blind.
