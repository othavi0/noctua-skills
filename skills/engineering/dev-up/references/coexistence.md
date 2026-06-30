# Coexistence — your tab group

Read this when [`SKILL.md`](../SKILL.md) step 4 shows **other `localhost:<port>` tabs already in
the group**. If yours is the only tab, none of this applies — skip it.

## What changed: one group *per session* now

The `claude-in-chrome` extension scopes a tab group **per Claude Code session** (via the native-
messaging `session_scope`/`tabGroupId` fields). Confirmed empirically: a fresh session's
`tabs_context_mcp` returns *"No tab group exists for this session"* until it creates its own — it
**cannot see other sessions' groups**. So the old hazard this file used to warn about — several
Claude instances living in one shared group, any instance clicking any tab — **no longer happens
between sessions**. (It used to: see anthropics/claude-code [#15173](https://github.com/anthropics/claude-code/issues/15173),
fixed; current behavior in [#23861](https://github.com/anthropics/claude-code/issues/23861) /
[#69542](https://github.com/anthropics/claude-code/issues/69542).)

**What's still real:** several `localhost` tabs **inside your own group** — because *you* ran
`dev-up` twice in this session, or dragged a tab in. The one-tab discipline below is now about not
confusing **your own** tabs, plus the shutdown last-tab hazard.

## The one rule

**You own exactly one tab: `TARGET_TAB_ID`** (`localhost:PORT`). Every interaction with the app
goes through it.

- Confirm the URL once when connecting, then use the `tab_id` directly; re-validate only if an
  action fails.
- **Never** act on a `localhost:<other-port>` tab — it's another project/port you opened earlier.
- **Never close or modify the tab group itself.** Operate only on your own `tab_id`.

## Last-tab hazard (shutdown)

Closing your tab is safe *unless it's the last one in the group* — then Chrome collapses the whole
group (and the next `tabs_context_mcp` with `createIfEmpty` starts fresh). Since the group is now
per-session, the only tabs at risk are **your own**, so this is rarely destructive — but if you
can't tell whether you have other tabs you still want, **leave the tab open** (or `navigate` it to
`about:blank`) and just stop the server and watcher. Never risk the group to tidy up one tab.

## Why the group is called "Claude (MCP)" and can't show the port

You can't rename the group to the port from a skill. The extension **hardcodes** the title
("Claude (MCP)", shown with a ✅ status badge) when it creates the group, and exposes **no** title
field: `tabs_create_mcp` takes zero parameters, `tabs_context_mcp` only `createIfEmpty`, and
`javascript_tool` runs in the page (content-script) context, which has no access to the
`chrome.tabGroups` API. So with multiple sessions open you'll see several identical "Claude (MCP)"
groups and can't tell which serves which port from the name alone.

- **Workaround (manual):** right-click the group in Chrome → rename it to the port. It sticks for
  the session, but the extension makes a fresh group next session, so you'd redo it.
- **Real fix:** a feature request to Anthropic to expose a group `title` on `tabs_create_mcp`
  (tracked alongside [#18983](https://github.com/anthropics/claude-code/issues/18983)).
- **Telling tabs apart without the name:** the tab's own URL (`localhost:PORT`) is the reliable
  discriminator — that's why `TARGET_TAB_ID` plus its confirmed URL is what you record, not the
  group name.
