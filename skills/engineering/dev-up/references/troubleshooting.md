# Troubleshooting

Read this from [`SKILL.md`](../SKILL.md) when startup fails, the server dies, or the tab stops
answering.

## `wait` verdicts

- `DIED`: the unit `dev-up-PORT` that `serve` started is gone. The log tail says why.
- `HTTP_5XX`: the server runs but its root throws. Fix the error in the log before the tab.
- `BUSY_OTHER pid=N`: another process holds the port, so this `serve` could not bind. Run `owner`.
- `BOUND_NO_HTTP`: something listens but does not speak HTTP on `/`. Check the dev command's port.
- `TIMEOUT`: nothing bound within 4 minutes while the process stayed alive.

## The launch fails

- A missing module after `preflight` said `ok`: a `node_modules` symlinked from another checkout
  breaks Turbopack (`FATAL`, "points out of the filesystem root") and serves the main checkout's
  workspace packages. Delete the symlink and install.
- `ModuleNotFoundError` in a Python app with a `.venv`: the launch ran the `python` that a version
  manager put on `PATH`. Launch through `serve`, which puts `.venv/bin` first.
- "Another server is already running" on a `FREE` port: some dev servers, recent Next among them,
  allow one instance per directory on any port. Offer to reuse that instance or stop it after the
  user confirms.
- The port comes back after a stop: a supervisor respawns it, such as a `turbo dev` or `bun dev` in
  a terminal or a process manager. Tell the user instead of killing it again.

## The app runs but behaves wrong

- OAuth returns to the production domain (a Supabase Site URL, a Google redirect URI). Copy the
  `?code=...` from that URL onto `http://localhost:PORT/<callback route>?code=...` in the same tab.
  The code works once and expires in minutes.
- An edited CSS file changes nothing in the tab. A Tailwind `--watch` inside the dev script can
  stop without logging an error. Compare the mtime of the generated CSS with the source before you
  trust a measurement.
- An edited `.env` changes nothing. `serve` copies the launching shell's environment, which a
  version manager (mise, asdf, direnv) may have loaded with old values. Source the file in the
  launch command as SKILL.md step 2.4 says, and Restart.

## The server went down with no error in the log

The watcher prints `SERVER DOWN`, or the hook says the server is down. `journalctl --user -u
dev-up-PORT` keeps the unit's exit reason after the unit is gone. Read it before relaunching:

- `oom-kill`, or `Killed` with nothing in the log: the kernel OOM killer, systemd-oomd, or the
  unit's own `MemoryMax`. The unit sits in the user manager's `app.slice`, which systemd-oomd
  watches under memory pressure, and it picks the heaviest unit there, often a large dev server.
  Relaunch through Restart with `serve --mem 4G` so the cap applies to the server alone, or raise
  the cap.
- `SIGTERM` while a subagent was working: a delegate killed it by name. Tell delegates that start
  servers to launch through `serve` and stop with `stop <port>`, never `pkill -f`.
- Relaunch only through `serve`. `nohup`, `setsid` and `disown` put the server outside the unit,
  so `stop`, `wait` and `owner` no longer see it as this skill's server.
- `serve` fails with `Unit dev-up-PORT.service was already loaded`: the old unit is still
  stopping, which takes up to 10 s. Run `stop PORT`, then `serve` again.

## claude-in-chrome calls fail

A call that returns "Frame ... is showing error page", or a failing `read_page` or `computer`,
means the tab is stuck, not necessarily the server. Find which one before retrying:

- Run `curl -s -o /dev/null -w "status=%{http_code}\n" http://localhost:PORT`. A 200 or 307 means
  the server is fine and the tab is the problem. A 307 to `/login` is the redirect for a request
  without a cookie, not an error.
- After a server restart the CDP link to the old tab often breaks and every call errors. Open a
  fresh tab with `tabs_context_mcp` and `tabs_create_mcp`, or `navigate` again, then confirm the URL.
- After 2 failed calls on the same tab, switch to curl and the log. One run spent six screenshots
  on a dead CDP link while the server answered 200.
- Calls hang with no error while curl returns 200: a native `alert`, `confirm` or `prompt` (often a
  `beforeunload` or a delete confirm) is open in a tab of the group and blocks every browser
  event. No MCP call closes it. Ask the user to dismiss it, then retry. Only after that, try a
  fresh tab or reconnect the extension.
- Every call fails with "Receiving end does not exist" after the session sat idle: the extension's
  service worker dropped the connection. Ask the user to run `/chrome` and pick Reconnect
  extension, then resume on the same `TARGET_TAB_ID`.

## "auto mode cannot determine the safety..." blocks the watcher

The permission classifier is down for a moment and fails `Monitor` or `Bash` with that message. It
is not a denial. Retry the Monitor within the next few actions and say in one line that the run has
no watcher meanwhile. A `Bash` call blocked the same way twice in a row goes to the user, who runs
it with the `!` prefix.
