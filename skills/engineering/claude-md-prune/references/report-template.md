# Report template

Fill this in for Phase 4. Keep the section order. Drop a section that has no items.

```
## CLAUDE.md Prune Report

### Summary
- Scope: <project only | plus the out-of-project files the user named>
- Files audited: <N>
- Drift issues found: <N>
- Files > 200 lines (prime candidates): <list>
- Result of this audit: the sum of everything classified CUT below — never a target percentage

### File: ./CLAUDE.md (root) — <N> lines

#### Drift (factual errors detected, and where a section is stale enough that the fix is a rewrite)
1. References path `X/Y/Z.md` which does not exist (renamed? deleted?)
2. Cites command `bun db:generate` but `package.json` does not contain it
3. Enum declared as `['a','b','c']` but `schema/foo.ts` shows `['a','b']`
4. ADR-0004 referenced as authoritative but ADR-0009 (2026-05-18) supersedes that flow
5. "Schema is push-only" (line 133): ADR-0009 made this more nuanced. Suggest rewording to: "..."

#### Sections to CUT
- Lines 14-30 "Stack": derivable from `package.json`
- Lines 35-71 "Topology": derivable from `ls`
- Lines 75-110 "Daily Commands": derivable from `package.json` scripts, except lines 80-82 (test, typecheck, lint), which stay
- Lines 217-228 "MCP Servers": derivable from `.mcp.json`

#### Sections to KEEP
- "Auth invariants P0" (lines 120-138): each bullet is a real isolation rule — KEEP
- "Anti-patterns banidos" (lines 250-266): each is a specific bug pattern — KEEP
- "Drizzle-kit push + TTY" (line 276): gotcha with specific symptom — KEEP

#### Sections to MOVE TO CLAUDE.local.md
- "I prefer succinct responses" (line 301): personal preference, not team-shared

#### Sections to MOVE TO WORKSPACE-LOCAL CLAUDE.md
- "Drizzle migration workflow" (lines 310-325): only applies to `packages/db`, not cross-cutting

#### Sections to MOVE TO HOOK
- "Always run `bun fix` after writes" (line 282): 100% enforcement → already a PostToolUse hook (no action needed)

### File: ./packages/api/CLAUDE.md (workspace) — <N> lines

[... per-file breakdown ...]
```
