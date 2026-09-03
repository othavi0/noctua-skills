---
name: claude-md-prune
description: >-
  Prune, audit, or trim a bloated, stale, or drifted CLAUDE.md. Use when the user calls
  CLAUDE.md too long, bloated, or outdated; says Claude is ignoring CLAUDE.md; when the
  file exceeds ~200 lines AND has obvious derivable content (stack lists, directory trees,
  command listings); or asks for a "Boris-style", "mistakes-only", or "minimal" CLAUDE.md.
  Also flags drift: paths, commands, enums, ADRs that no longer match the code. Not for
  adding content to CLAUDE.md or generating one from scratch — that's a different skill.
---

# claude-md-prune

This skill aggressively removes content from CLAUDE.md files that Claude can already infer from the code, and flags claims in the doc that no longer match reality (subtractive only — see Anti-instructions).

## Why this skill exists

Two sources converge on the same operational philosophy:

**Anthropic best-practices** ([code.claude.com/docs/en/best-practices](https://code.claude.com/docs/en/best-practices)):

> Treat CLAUDE.md like code: review it when things go wrong, prune it regularly, and test changes by observing whether Claude's behavior actually shifts.
>
> For each line, ask: "Would removing this cause Claude to make mistakes?" If not, cut it.
>
> Bloated CLAUDE.md files cause Claude to ignore your actual instructions.

**[howborisusesclaudecode.com](https://howborisusesclaudecode.com)** (a third-person write-up of how Boris Cherny, creator of Claude Code, works):

> Ruthlessly edit your CLAUDE.md over time. Keep iterating until Claude's mistake rate measurably drops.

Anthropic's best-practices page (quoted above) draws the same line in its include/exclude table: keep the file to rules that fix recurring mistakes; anything Claude can figure out by reading the code, and standard language conventions, belong elsewhere.

The CLAUDE.md is **advisory**: the model can drop a rule under context pressure, and there is no published adherence figure. For rules that must execute 100% of the time, use a **hook** instead. As the Anthropic quote above says, bloat makes Claude ignore the instructions that matter.

Claude Code's built-in `/doctor` (2.1.206+) also proposes trimming derivable content, but as a single pass with no drift fact-checking or per-file approval — this skill adds both.

## When to trigger

Trigger on any of these:

- User says "audit", "refine", "trim", "prune", "shrink", "refactor" CLAUDE.md
- User describes CLAUDE.md as "too long", "bloated", "stale", "outdated", "messy"
- User says Claude is "ignoring CLAUDE.md", "didn't follow the rule", "asked something that was in the docs"
- User mentions "Boris-style" / "mistakes-only" / "minimal" CLAUDE.md
- User asks for a project audit or documentation audit and CLAUDE.md files exist
- During unrelated work, you notice a CLAUDE.md file is > 200 lines AND has obvious derivable content (stack lists, directory trees, command listings) — proactively offer.

**Out of scope** — do not trigger when the user wants to:

- ADD content to CLAUDE.md, or generate one from scratch — if a complementary add-skill (e.g. `claude-md-improver`) is installed, route there; otherwise flag what's missing in the report and stop
- Capture end-of-session learnings into CLAUDE.md — that's a capture workflow, not an audit

Run this skill periodically (every 1-3 months, or whenever a CLAUDE.md grows beyond ~200 lines).

## Workflow

Five phases. Always present the report BEFORE applying changes. On a long audit (monorepo, many files), if the conversation gets compacted mid-run, re-invoke this skill before Phases 4-5 — after compaction only a skill's first ~5k tokens are re-attached, and the tail of this workflow can silently vanish.

### Phase 1: Discovery

Find every CLAUDE.md in scope. Default scope is the current project.

Locations to check:

- `./CLAUDE.md` (project root)
- `./CLAUDE.local.md` (personal, gitignored — may or may not exist)
- Any `./**/CLAUDE.md` in monorepos (workspace/package-level)
- `~/.claude/CLAUDE.md` (global) — **only if user explicitly asks for global scope**
- `~/.claude/memory/*.md` (auto-memory) — **only if user explicitly asks**. Same Boris filter applies: each memory file should answer "would removing this make Claude make mistakes / lose non-obvious knowledge?" Cut derivable filesystem listings, memories that point back to CLAUDE.md without adding info, generic philosophy already known to Claude. KEEP specific gotchas, citations of real incidents, decision rationales, and project context not in the code.

For each file: record line count and approximate size. **Files > 200 lines are prime candidates** for aggressive pruning. Files < 50 lines might still benefit from drift detection but rarely need cuts. Memory files are typically 10-50 lines each — apply per-file: does the description claim non-obvious knowledge that the body actually delivers, or is the body just paraphrasing the description? If paraphrasing, cut.

Confirm the scope with `AskUserQuestion` before proceeding — options: project only (default, recommended: matches the common case and avoids touching shared or personal files by accident), project + `CLAUDE.local.md`, project + auto-memory (`~/.claude/memory/*.md`), or all of the above including global `~/.claude/CLAUDE.md`.

Then do one fast read-through of every CLAUDE.md in scope and tag each section with a rough call — likely CUT, or likely KEEP/rewrite — using the Phase 3 test below. This tagging is provisional; Phase 3 makes it final. It exists only to scope Phase 2.

### Phase 2: Drift detection (fact-checking against code)

For each section tagged likely KEEP or likely rewrite, verify that the **claims in the doc still match the code**. Skip full fact-checking on sections tagged likely CUT — a section leaving the file doesn't need its claims re-verified line by line; a quick glance is enough to catch the case where a whole "stale workflow" section is both bloat and drift (see `references/drift-checks.md`, point 3 under "What to do with drift findings"). This is the most valuable phase of what's left — silent drift is a more common failure mode than bloat.

Detect the project's primary manifest file(s) so checks adapt to the stack — the full manifest table per stack lives in `references/drift-checks.md` (single source of truth; it also covers Makefile/justfile/Taskfile).

For each factual claim in a likely-KEEP/rewrite section, verify:

- **Paths** mentioned exist on the filesystem
- **Commands** referenced (e.g., `bun db:sync`, `cargo run`) appear in the manifest's scripts/tasks
- **Functions, types, classes, enums, constants** cited via Grep — values still match what's documented
- **ADRs / decision documents** referenced still exist; check if a newer ADR has superseded the workflow described
- **Environment variables** documented still appear in the env validation source (zod schema, dotenv-vault, T3 env, etc.)
- **External dependencies** mentioned (e.g., "uses XYZ library") still appear in the manifest

Use parallel tool calls (multiple Read/Grep in one message) since these checks are independent.

See `references/drift-checks.md` for the full checklist per stack and example evidence patterns.

Phase 2 is complete only when every claim type in that checklist has been checked against the code for every likely-KEEP/rewrite section in scope — not just until the first drift is found.

### Phase 3: Categorize content (the Boris filter)

For each section or bullet in the CLAUDE.md, apply the canonical test:

> **Would Claude make mistakes if I removed this line?**

If "no" → it's noise. If "yes" → preserve. When unclear, default to **ASK the user** rather than cut blindly; the user may know history (past bugs, specific incidents) that explains why an apparently generic rule exists.

Classify each section/bullet into one of five buckets:

#### CUT (derivable from code or generic knowledge)

Common patterns to remove:

- **Stack / dependency lists** (read the manifest)
- **Directory structure trees** (read the filesystem)
- **Command listings** (read manifest scripts)
- **Environment variable lists** (read env validation source)
- **Architecture descriptions / explainers** (Claude reads the code)
- **Per-folder descriptions** ("what each folder does")
- **Tutorials, onboarding instructions** (belongs in README/docs/)
- **Generic best-practices** Claude already knows, including code style that mirrors language/framework defaults (`references/cut-criteria.md` #8)
- **Generic linter rules** (the linter config exists)
- **Long verbose explanations** when a one-liner would do

See `references/cut-criteria.md` for detailed examples per category.

#### KEEP (mistakes-recurrent or genuinely non-obvious)

These survive the filter:

- **P0 invariants** (e.g., "never import X from Y", "never set cookie domain to Z")
- **Gotchas with specific symptom + workaround** (framework bugs, version-specific issues, library quirks)
- **Anti-patterns banned with reason** (when language/framework default would be a bug here)
- **Non-obvious architectural decisions** (server-wins on conflict, ownership rules, isolation boundaries)
- **Specific bugs Claude has made before** (the compounding-engineering log)
- **Cross-cutting rules** that span multiple files

See `references/keep-criteria.md` for examples and rationale per category.

#### MOVE TO `CLAUDE.local.md` (personal/gitignored)

- Personal preferences ("I prefer succinct responses", "I like Portuguese explanations")
- Per-user paths or aliases
- Anything that should not be shared with the team

#### MOVE TO WORKSPACE-LOCAL CLAUDE.md

In a monorepo, push down. Root `CLAUDE.md` should only carry **cross-cutting** items. A mistake that only applies to one package or workspace lives in that package's CLAUDE.md, where it's automatically loaded when Claude works in that directory tree.

#### CONVERT TO HOOK

If a rule requires 100% adherence (formatter, linter trigger, block on certain file writes), convert to a hook. Examples:

- "Always run `bun fix` after writes" → PostToolUse hook
- "Never commit without running tests" → PreToolUse hook on commit
- "Block writes to `.env`" → PreToolUse hook

Flag candidates here — actual hook creation is out of scope for this skill (suggest `update-config` skill).

### Phase 4: Quality report

ALWAYS output the full report before applying any changes — nothing gets written until Phase 5's approval.

Format:

```
## CLAUDE.md Prune Report

### Summary
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
- Lines 75-110 "Daily Commands": derivable from `package.json` scripts
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

### Phase 5: Apply with approval

Confirm which files to apply with `AskUserQuestion` — one question per file (or a single question offering "all files", "let me pick", "none" when the audit covers many files), each option naming what would change (e.g., "apply — cuts 6 sections, rewords 1" vs. "skip this file").

For each approved file, apply the cut by `Edit`, one call per approved line range, never by writing the whole file from scratch — a full rewrite is exactly how a KEEP line silently disappears or gets paraphrased into new content, which Anti-instructions bans. Always show the diff for each edit before applying it. After all edits to a file are applied, re-read it and confirm every item the report marked KEEP is still present, verbatim — treat a missing or reworded KEEP line as a bug in the apply step, not an acceptable side effect of trimming.

After applying:

- Print the final line count reduction (this validates the work and reinforces the habit)
- Suggest the user re-run this skill periodically (every 1-3 months, or whenever a CLAUDE.md grows above ~200 lines) — and offer to create a scheduled task firing this skill on that cadence, so the recurrence doesn't depend on anyone's memory
- If hook candidates were identified, suggest invoking `update-config` skill to wire them up

## Anti-instructions

These are the easy ways to misuse the skill — avoid each:

- **Do not add new content.** This skill is subtractive. If you spot a missing rule, flag it in the report but do not write it — if a complementary add-skill is installed, point the user there; otherwise the flag is enough.
- **Do not invent gotchas.** Only KEEP content that's already in the file. The skill does not generate new project-specific rules from imagination.
- **Do not cut without asking when unclear.** A rule that looks generic might cover an actual past incident only the user remembers. When in doubt, ask: "Did this line ever fix a real bug?"
- **Do not touch `~/.claude/CLAUDE.md` (global)** unless the user explicitly opts in. Default scope is the current project.
- **Do not delete CLAUDE.md files entirely** during prune. Even a tiny CLAUDE.md is acceptable if it carries one real gotcha. Empty files are fine; non-existence is suspicious.
- **Do not preserve content "just in case".** Aggressive is the goal — but always with the user's approval per file.

## References

- `references/cut-criteria.md` — categories of removable content with examples per stack
- `references/keep-criteria.md` — what survives the filter, with rationale
- `references/drift-checks.md` — fact-checking checklist universal across languages
