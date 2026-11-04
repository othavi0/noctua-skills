# Troubleshooting

Read this when `wait` says anything but `READY`, the server dies, or the session stops answering.

## `wait` verdicts

- `DIED`: the unit `dev-up-PORT` is gone; the log tail says why.
- `HTTP_5XX`: the server runs but its root throws. Fix the error in the log first.
- `BUSY_OTHER pid=N`: another process holds the port. Run `owner`.
- `BOUND_NO_HTTP`: something listens but does not speak HTTP on `/`. Check the dev command's port.
- `TIMEOUT`: nothing bound within 4 minutes while the process stayed alive.

## The launch fails

- A missing module after `preflight` said `ok`: a `node_modules` symlinked from another checkout
  breaks Turbopack (`FATAL`, "points out of the filesystem root"). Delete the symlink and install.
- `ModuleNotFoundError` in a Python app with a `.venv`: the launch ran another `python`. Launch
  through `serve`, which puts `.venv/bin` first on `PATH`.
- "Another server is already running" on a `FREE` port: recent Next allows one dev server per
  directory on any port. Reuse that instance, or stop it once the user confirms.
- An edited `.env` changes nothing: `serve` copies the launching shell's environment, which a
  version manager may have loaded with old values. Source the file in the launch command and
  Restart.

## The server went down with no error in the log

`journalctl --user -u dev-up-PORT` keeps the unit's exit reason. `oom-kill`, or `Killed` with an
empty log, is the OOM killer or systemd-oomd: Restart with `serve --mem 4G`. A `SIGTERM` while a
subagent worked means it killed the server by name: delegates start servers through `serve` and
stop them with `stop PORT`. Relaunch only through `serve`, so `stop`, `wait` and `owner` still see
the server as this skill's.

## The session

- A page on `about:blank`, or a window that takes focus without the class `agent-browser`: a call
  went to `agent-browser` directly and the daemon relaunched the browser. `S ab PORT close`, then
  `S ab PORT open http://localhost:PORT/`.
- `dev-up: the session on port PORT had closed; reopened it at ...` on stderr: the daemon stopped
  after 30 minutes idle, and `ab` reopened the session at the root with the same profile, so the
  login stays. Navigate back to the route you were on before acting.
- `Cannot use storage_state with profile`: `--state` went together with a profile. Open first,
  then `S ab PORT state load <file>`, then open again; `show` and `hide` do exactly that.
- `S browser PORT` shows a full browser where `chrome-headless-shell` used to run: a cache cleaner
  deleted it from `~/.cache/ms-playwright`. `npx playwright install chromium-headless-shell` brings
  back the half-RAM session.
- agent-browser warns that the browser is behind the stable release: the warning is about the
  browser binary; a session on `localhost` keeps working.
