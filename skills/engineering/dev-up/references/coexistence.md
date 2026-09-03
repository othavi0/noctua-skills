# Coexistence — your tab group

Read this when [`SKILL.md`](../SKILL.md) step 4 shows **other `localhost:<port>` tabs already in
the group**. If yours is the only tab, none of this applies — skip it.

## One group *per session*

The extension scopes a tab group **per Claude Code session** — a fresh session cannot see other
sessions' groups, so instances never share one. What's still real: several `localhost` tabs
**inside your own group** (*you* ran `dev-up` twice, or dragged a tab in). The one-tab discipline
below is about not confusing **your own** tabs, plus the shutdown last-tab hazard.

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

## The group title can't show the port

The extension hardcodes the group title ("Claude (MCP)") and exposes no title field — with several
sessions open you'll see identical groups. The tab's own URL (`localhost:PORT`) is the reliable
discriminator; that's why you record `TARGET_TAB_ID` plus its confirmed URL, not the group name.
