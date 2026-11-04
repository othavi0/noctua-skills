# Shutting down

Run this only when the user asks. `S` is the script command as [`SKILL.md`](../SKILL.md) spells it.

1. `S owner PORT` and `S state PORT show`.
2. `via=dev-up`: `S stop PORT`. `via=other`: the server predates this skill; leave it up unless the
   user names it, then `S stop PORT --force`. `STILL_BOUND` after that means a supervisor respawns
   it: tell the user.
3. `TaskStop` the `watcher_task` when `watcher_alive=yes`.
4. `S ab PORT close`. It closes this port's browser and no other session.
5. `S state PORT rm`. The log stays. The profile and saved login in `~/.local/state/dev-up-ab`
   stay for the next run; delete `profiles/PORT-*` and `auth-PORT.json` there when the user asks
   to forget the login.
6. The dashboard serves every session: `agent-browser dashboard stop` once
   `agent-browser session list` prints no session.

Done when `S owner PORT` prints `FREE` and `S state PORT show` prints `no state for PORT`.
