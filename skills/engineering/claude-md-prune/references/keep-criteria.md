# Keep criteria

Content that survives the canonical test in SKILL.md Phase 3 ("Would Claude make mistakes if I removed this line?"). These are the survivors after applying the Boris/Anthropic filter.

When the user pushes back on cutting something, it's usually because it falls into one of these categories — make sure to recognize them.

## 1. P0 invariants (isolation, security, contract)

Hard rules where violation is a bug — usually about boundaries between modules, services, or trust zones.

**Looks like:**

- "App X never imports module Y" (isolation between auth/data realms)
- "Never set cookie domain to .example.com" (subdomain isolation)
- "Service A does not call Service B; coordination is via shared DB" (architecture contract)
- "Never expose `SUPABASE_SERVICE_ROLE_KEY` to the client" (security)

**Why keep:** these are decisions that reading the code does not reveal. A new module would happily import from anywhere — only the rule prevents it.

## 2. Gotchas (specific symptom + workaround)

A concrete bug or quirky behavior of the framework/library, plus what to do about it.

**Looks like:**

- "Drizzle-kit push requires TTY confirmation in destructive changes — fails in scripted CI. In dev, run interactive."
- "`React.forwardRef` is deprecated in React 19 — use `ref` as a normal prop."
- "Next.js `experimental.serverActions.bodySizeLimit` defaults to 1MB; uploads via base64 inline need it raised."
- "Drizzle 0.45.x `db.execute()` returns timestamp as string (driver bypass) — coerce with `toDate()` at boundary."

**Why keep:** these are not guessable from reading the code. They are framework- or version-specific quirks that took someone hours to debug.

## 3. Anti-patterns banned with reason

A list of "don't do this", each with **why** for the current project/stack.

**Looks like:**

- "No `console.log` in production — use structured logger; otherwise our log shipper drops the line."
- "No `key={index}` in `.map()` — caused stale-state bug in incident #42."
- "No `useMemo`/`useCallback` — React Compiler is enabled; manual memo is redundant or actively harmful."
- "No barrel files in `packages/ui/src/` — they break tree-shaking with our bundler config."

**Why keep:** each item is a specific decision against a default that would otherwise look reasonable. Without the rule, Claude (or any contributor) would reach for the default and reintroduce the bug.

## 4. Non-obvious architectural decisions

A decision that surprised someone in the past or that conflicts with common assumptions.

**Looks like:**

- "On conflict during pull: server-wins for server-owned data" (one of several valid choices, others would be equally defensible)
- "Leaderboard uses raw SQL + JOIN to `public.user` (Better Auth table), not `auth.users`" (one specific table to grep, not the obvious one)
- "Schema sync is via automated CI PR from the upstream repo — never edit the local schema in isolation" (workflow that's not visible in the code itself)
- "Ownership: catalog tables are owned-by-dashboard; client tables are owned-by-ecommerce; writes coordinate through shared DB" (cross-repo contract)

**Why keep:** these are decisions visible nowhere in the code. They affect every modification in that area.

## 5. Specific past bugs (compounding-engineering log)

A bullet for each time Claude made a mistake the team had to correct.

**Looks like:**

- "`db.execute<T>` returns columns in literal snake_case — never `SELECT *` when shape is camelCase (incident #23)"
- "FK names auto-generated past 63 chars get truncated by Postgres → drizzle-kit push loops on phantom diff. Give explicit name."
- "Unique constraint composite: declare columns in `.on()` in same order as table definition — drizzle-kit reads pg_attribute attnum and generates phantom diff if mismatched."

**Why keep:** each one is a real production-or-dev incident. Removing reintroduces the bug eventually.

## 6. Cross-cutting rules (touch multiple files)

Rules that don't belong to a single workspace or directory — they apply project-wide.

**Looks like:**

- "IDs in server actions: `crypto.randomUUID()` everywhere; no nanoid, no UUIDs from DB"
- "Validation: Zod `safeParse` at every boundary; never `parse` (don't throw at boundaries)"
- "Money: `numeric(10, 2)` for product prices; `numeric(12, 2)` for order totals; never `real`/`double`"

**Why keep:** these apply to dozens of files. Localizing them to one package's CLAUDE.md would lose coverage; baking them into hooks would be too coarse. Root CLAUDE.md is the right place.

## How to spot a survivor

For each candidate, ask two questions, then apply the canonical test from SKILL.md Phase 3:

1. **Is this guessable from reading the code?** If yes → cut.
2. **Is this a language/framework default Claude already knows?** If yes → cut.
3. Otherwise, apply the canonical test. If it did fix a real bug, or encodes a non-obvious decision → KEEP.

When in doubt on the canonical test, ask the user — they remember the history.

## How much survives

There is no fixed percentage to aim for. How much a CLAUDE.md loses in a first prune depends entirely on how much of it was written as documentation (stack lists, architecture explainers, tutorials — almost all of that cuts) versus written as a mistakes log (gotchas, P0 invariants, incident notes — almost all of that stays). The result of an audit is the sum of what got classified CUT in Phase 3, never a target to hit.
