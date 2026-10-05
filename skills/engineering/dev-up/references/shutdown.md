# Shutting down

Run this only when the user asks. `S` stands for the `bash .../scripts/dev-up.sh` command exactly
as `SKILL.md` spells it, with the skill's base directory filled in.

1. `S state PORT show`. The `owner` decides what is yours: `self` means this session started the
   server, `reused` means it was already running and stays up. Watcher and tab are yours either way.
2. `owner=self` only: `TaskStop` the `server_task`, then `S stop PORT`. `STILL_BOUND` means a
   supervisor respawns the server (a `turbo dev` in a terminal, a process manager): tell the user
   and leave it.
3. `TaskStop` the `watcher_task` when it is not blank. An expired Monitor needs nothing.
4. Close the tab with `tabs_close_mcp`, only when the recorded `tab_id` appears in a fresh
   `tabs_context_mcp` list on `localhost:PORT`. A recorded id can point at another URL by now, and
   matching by what looks like yours once closed the wrong tab. Leave the group itself alone. When
   the tab is the last one in the group, closing it collapses the group
   ([`coexistence.md`](coexistence.md)); when unsure, navigate it to `about:blank` instead.
5. `S state PORT rm` removes the state file and the log.

## A state file from another session

`TaskStop` and `tabs_close_mcp` only reach ids of this session. A state whose ids fail with "No task
found" belongs to a dead session: its watcher already ended with that session, and its tab sits in
another group you cannot see. `S owner PORT` with `mine=yes` lets you `S stop PORT` after
`S state PORT set owner=self`; otherwise leave the server up. Say which tab may remain open, then
`S state PORT rm`.
