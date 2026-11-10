---
name: claude-md-prune
description: >-
  Prune, audit, or trim a bloated, stale, or drifted CLAUDE.md. Use when the user calls
  CLAUDE.md too long, bloated, or outdated; says Claude is ignoring CLAUDE.md; when the
  file exceeds ~200 lines AND has obvious derivable content (stack lists, directory trees,
  command listings); or asks for a "Boris-style", "mistakes-only", or "minimal" CLAUDE.md.
  Also flags drift: paths, commands, enums, ADRs that no longer match the code. Not for
  adding content to CLAUDE.md or generating one from scratch (claude-md-improver).
---

# claude-md-prune

This skill removes from CLAUDE.md what Claude gets cheaply from the code, and flags claims that no longer match the code. It is subtractive only (see Anti-instructions).

## Workflow

Five phases. Always present the report BEFORE applying changes.

### Phase 1: Discovery

Find every instruction file in scope. Default scope is the current project, and it needs no confirmation:

- `./CLAUDE.md` and `./.claude/CLAUDE.md`
- `./.claude/rules/**/*.md`
- Every file a CLAUDE.md in scope pulls in with an `@path` import, followed through nested imports (Claude Code stops at four hops). An imported file loads with the file that imports it and costs the same context as an inline section.
- Any `./**/CLAUDE.md` in subdirectories (workspace/package-level)

The first three load at session start, so their bloat is paid in every session: prune them first. A subdirectory CLAUDE.md and a rule with `paths:` frontmatter load only when Claude touches a matching file. Their bloat costs less, their drift costs the same.

Out of the project, only when the user names it: `./CLAUDE.local.md` (personal), `~/.claude/CLAUDE.md` and `~/.claude/rules/` (global), memory files (see Memory files below). Ask with `AskUserQuestion` only when the request leaves it unclear whether one of these is wanted, such as "clean up all my Claude instructions". Otherwise proceed with the project scope and state it in the report.

For each file: record line count and approximate size. **Files > 200 lines are prime candidates** for aggressive pruning. Files < 50 lines might still benefit from drift detection but rarely need cuts.

Then do one fast read-through of every file in scope and tag each section with a rough call — likely CUT, or likely KEEP/rewrite — using the Phase 3 tests below. This tagging is provisional; Phase 3 makes it final. It exists only to scope Phase 2.

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

### Phase 3: Categorize content

For each section or bullet in the CLAUDE.md, apply two tests in order:

> 1. **Would Claude make mistakes if I removed this line?**
> 2. **Would Claude spend many tool calls rediscovering it in every session?**

"Yes" to either → preserve. "No" to both → it's noise. Test 2 is about cost, not possibility: everything in a repo is derivable eventually. A line passes test 2 when it replaces a search that is long or that lands on the wrong place first (the one command that runs a single test, the directory that actually owns a feature when the obvious name points elsewhere). A line that restates what one `ls` or one manifest read shows fails it. When unclear, default to **ASK the user** rather than cut blindly; the user may know history (past bugs, specific incidents) that explains why an apparently generic rule exists.

Classify each section/bullet into one of five buckets:

#### CUT (cheaply derivable from code, or generic knowledge)

Common patterns to remove:

- **Stack / dependency lists** (read the manifest)
- **Directory structure trees** (read the filesystem); keep the one-line pointer that passes test 2
- **Command listings** (read manifest scripts); keep the commands that verify work (test, typecheck, lint, single test) and any command Claude would not guess from the script names
- **Environment variable lists** (read env validation source)
- **Architecture descriptions / explainers** (Claude reads the code)
- **Per-folder descriptions** ("what each folder does")
- **Tutorials, onboarding instructions** (belongs in README/docs/)
- **Generic best-practices** Claude already knows, including code style that mirrors language/framework defaults (`references/cut-criteria.md` #8)
- **Generic linter rules** (the linter config exists)
- **Long verbose explanations** when a one-liner would do

See `references/cut-criteria.md` for detailed examples per category.

#### KEEP (prevents a mistake, or saves a long rediscovery)

These survive:

- **P0 invariants** (e.g., "never import X from Y", "never set cookie domain to Z")
- **Gotchas with specific symptom + workaround** (framework bugs, version-specific issues, library quirks)
- **Anti-patterns banned with reason** (when language/framework default would be a bug here)
- **Non-obvious architectural decisions** (server-wins on conflict, ownership rules, isolation boundaries)
- **Specific bugs Claude has made before** (the compounding-engineering log)
- **Cross-cutting rules** that span multiple files
- **Costly-to-rediscover pointers** (test 2): a non-guessable command, or where a feature really lives when the obvious name misleads

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

ALWAYS output the full report before applying any changes. Nothing gets written until Phase 5's approval.

Use the format in `references/report-template.md`. State the scope you audited in the Summary. The result of an audit is the sum of everything classified CUT, never a target percentage.

### Phase 5: Apply with approval

Confirm which files to apply with `AskUserQuestion` — one question per file (or a single question offering "all files", "let me pick", "none" when the audit covers many files), each option naming what would change (e.g., "apply — cuts 6 sections, rewords 1" vs. "skip this file").

For each approved file, apply the cut by `Edit`, one call per approved line range, never by writing the whole file from scratch — a full rewrite is exactly how a KEEP line silently disappears or gets paraphrased into new content, which Anti-instructions bans. Always show the diff for each edit before applying it. After all edits to a file are applied, re-read it and confirm every item the report marked KEEP is still present, verbatim — treat a missing or reworded KEEP line as a bug in the apply step, not an acceptable side effect of trimming.

After applying:

- Print the line count before and after. That number is not the result: tell the user the prune worked if, over the next sessions, Claude follows the surviving rules more often and re-asks or re-explores nothing that was cut. A cut line that causes either goes back in.
- Suggest the user re-run this skill periodically (every 1-3 months, or whenever a CLAUDE.md grows above ~200 lines) — and offer to create a scheduled task firing this skill on that cadence, so the recurrence doesn't depend on anyone's memory
- If hook candidates were identified, suggest invoking `update-config` skill to wire them up

## Memory files

Opt-in only: `~/.claude/memory/*.md` and the per-project auto-memory in `~/.claude/projects/*/memory/`. These are notes, not project instructions, so Phase 2 does not apply unless a note cites a path or command. Judge each file whole:

- CUT a note that lists what the filesystem shows, points back to CLAUDE.md without adding anything, restates generic philosophy, or whose body only paraphrases its own description.
- KEEP specific gotchas, real incidents, decision rationales, and project context that is not in the code.

Report and apply as in Phases 4-5, one approval per file. A deleted note's line in the `MEMORY.md` index goes with it, under that note's approval.

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
- `references/report-template.md` — the Phase 4 report format
- `references/keep-criteria.md` — what survives the filter, with rationale
- `references/drift-checks.md` — fact-checking checklist universal across languages
