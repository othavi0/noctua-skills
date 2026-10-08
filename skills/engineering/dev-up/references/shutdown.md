# Shutting down

Run this only when the user asks. `S` stands for the `bash .../scripts/dev-up.sh` command exactly
as `SKILL.md` spells it, with the skill's base directory filled in.

1. `S owner PORT` and `S state PORT show`.
2. `via=dev-up`: `S stop PORT`. `stop` stops the unit `dev-up-PORT` that `serve` started, and
   systemd sends SIGTERM to every process in it and nothing else, then SIGKILL after 10 s.
   `via=other`: the server was already running before dev-up, or a dev-up older than the
   systemd unit started it, so leave it up unless the user names it; then `S stop PORT --force`.
   `STILL_BOUND` after `--force` means a supervisor respawns it (a `turbo dev` in a terminal, a
   process manager) or it ignores SIGTERM: tell the user and leave it.
3. `TaskStop` the `watcher_task` when `watcher_alive=yes`.
4. Close the tab with `tabs_close_mcp`, only when the recorded `tab_id` appears in a fresh
   `tabs_context_mcp` list on `localhost:PORT`. A recorded id can point at another URL by now, and
   matching by what looks like yours once closed the wrong tab. Leave the group itself alone. When
   the tab is the last one in the group, closing it collapses the group
   ([`coexistence.md`](coexistence.md)); when unsure, navigate it to `about:blank` instead.
5. `S state PORT rm`. The log stays for later reading; the next `serve` rotates it.

## A state file from another session

`owner` says `state=other`. `TaskStop` and `tabs_close_mcp` only reach ids of this session: the
other session's watcher ended with it, and its tab sits in a group you cannot see. Stop the server
as in step 2, say which tab may remain open, then `S state PORT rm`.
