# Shutting down

Run this only when the user asks. `S` stands for the `bash .../scripts/dev-up.sh` command exactly
as [`SKILL.md`](../SKILL.md) spells it, with the skill's base directory filled in.

1. `S owner PORT` and `S state PORT show`.
2. Stop the server.
   - `via=dev-up` → `S stop PORT`. systemd sends SIGTERM to every process in the unit
     `dev-up-PORT`, then SIGKILL after 10 s.
   - `via=other` → the server was running before this skill. Leave it up unless the user names
     it. Then `S stop PORT --force`. `STILL_BOUND` after `--force` means a supervisor respawns it
     (a `turbo dev` in a terminal, a process manager): tell the user and leave it.
3. `TaskStop` the `watcher_task` when `watcher_alive=yes`.
4. Close the tab: `tabs` with `action: "close"`, `tab: "dev-PORT"`. Close any `dev-PORT-<name>`
   tab a subagent left in the `tabs` list too. Leave every other tab alone.
5. `S state PORT rm`. The log stays for later reading. The next `serve` rotates it.

## A state file from another session

`owner` says `state=other`. That session's watcher ended with it, so skip step 3. The tab id
`dev-PORT` is the same for every session on this machine, so steps 2, 4 and 5 work as written.
