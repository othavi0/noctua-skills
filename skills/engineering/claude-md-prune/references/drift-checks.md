# Drift checks

The drift detection phase is often more valuable than the cutting phase: silent drift (doc says X, code says Y) leads Claude to apply rules that don't exist anymore. This file lists the universal checks; parallelize them across the doc.

## Contents

- How to read a CLAUDE.md for claims (the 10 claim types)
- Universal manifest detection (table per stack)
- Common drift patterns to flag (patterns 1-8)
- Parallelization
- What to do with drift findings

## How to read a CLAUDE.md for claims

Pass through the doc and extract every claim that mentions a specific artifact in the code:

| Claim type | Example | What to check |
|---|---|---|
| File path | "see `packages/db/migrations/triggers.sql`" | Does the file/dir exist? |
| Command | "run `bun db:generate`" | Is it a script in the manifest? |
| Function / method | "uses `requireCapability(cap)`" | Grep — does it exist with that signature? |
| Type / interface | "returns `ActionResult<T>`" | Grep type declaration — same shape? |
| Enum / constant | "`actorType` is one of `['user','system']`" | Read the schema source — values match? |
| Env var | "set `DATABASE_URL`" | Is it in the env validation source? |
| Library / dependency | "uses `react-markdown`" | Is it in the manifest? Same major version? |
| ADR / doc reference | "see ADR-0006" | Does the ADR exist? Has a later ADR superseded it? |
| Workflow step | "`bun db:sync` after editing schema" | Does the script exist? Does its current implementation match the description? |
| Configuration value | "`bodySizeLimit = '5mb'`" | Read the config file — same value? |

Patterns #1-#6 below elaborate the File path, Command, Enum/constant, ADR, Library, and Env var rows with symptom/check/fix detail. The remaining rows — Function/method, Type/interface, Workflow step, Configuration value — have no dedicated pattern; this table is their authority.

For each claim that fails verification, record:

- The location in the CLAUDE.md (line number / section)
- What the claim says
- What the code shows
- A brief suggestion: "rewrite to ...", "remove (artifact no longer exists)", "update reference to ..."

## Universal manifest detection

Detect the project's primary manifest(s) so checks use the right source. A project may have multiple (e.g., a monorepo with both `package.json` at root and `pyproject.toml` in one package).

| Manifest file | Stack | What it carries |
|---|---|---|
| `package.json` | JS / TS / Node / Bun / Deno (with import map) | `dependencies`, `devDependencies`, `scripts`, `workspaces` |
| `Cargo.toml` | Rust | `[dependencies]`, `[[bin]]`, `[workspace]` |
| `pyproject.toml` | Python (modern) | `[project.dependencies]`, `[tool.uv]`, `[tool.poetry]` |
| `requirements.txt` / `uv.lock` | Python (legacy or lock) | direct deps |
| `go.mod` | Go | `require` directives, `go` version |
| `Gemfile` | Ruby | `gem` directives |
| `pom.xml` | Java (Maven) | `<dependencies>`, `<modules>` |
| `build.gradle` / `build.gradle.kts` | Java / Kotlin (Gradle) | `dependencies { ... }` |
| `composer.json` | PHP | `require`, `scripts` |
| `mix.exs` | Elixir | `deps`, `aliases` |
| `Package.swift` | Swift | `dependencies` |
| `pubspec.yaml` | Dart / Flutter | `dependencies`, `dev_dependencies` |
| `Makefile` | Any (build orchestration) | `target:` rules |
| `justfile` | Any (just task runner) | recipes |
| `Taskfile.yml` | Any (Task task runner) | tasks |

Always check manifests at both the repo root and any workspace/package roots in monorepos.

## Common drift patterns to flag

These are the highest-frequency drift cases observed in audits. Look for them first.

### 1. Renamed or removed paths

A doc that says "see `packages/foo/migrations/`" when the project moved to push-only schema and removed that directory entirely.

**Symptom in the doc:** specific paths cited in instructions.
**Check:** filesystem existence.
**Likely fix:** update path or remove the instruction if the workflow changed.

### 2. Commands removed from the manifest

A doc that says "run `bun db:migrate` in prod" when `package.json` no longer has that script (project shifted to push-only or to CI-driven sync).

**Symptom in the doc:** "run X" instructions referencing a command.
**Check:** manifest scripts/targets.
**Likely fix:** remove the instruction or update to current command name.

### 3. Enum / type values diverged

A doc that says "`actorType` is one of `['user', 'apiKey', 'system']`" when the schema shows `['user', 'system']` (the `apiKey` variant was removed during a refactor).

**Symptom in the doc:** enum values, type unions, or specific string literals.
**Check:** Grep the source declaration; compare values.
**Likely fix:** update the enum list or remove the section if no longer relevant.

### 4. ADR superseded but doc not updated

A doc that cites ADR-0004 as the authoritative description of a workflow when ADR-0009 has since changed the flow (e.g., "manual sync" → "automated CI PR").

**Symptom in the doc:** ADR references, words like "manually", "sync", or workflow descriptions tied to a specific decision.
**Check:** list ADRs (often in `docs/adr/` or `decisions/`); look for newer ones in the same topic area; read the most recent ADR's "Supersedes" or "Replaces" line.
**Likely fix:** update reference to the newest ADR; rewrite the workflow description.

### 5. Library version assumption no longer matches

A doc that says "uses `react-markdown` v8" when the manifest now shows v9 with breaking API changes.

**Symptom in the doc:** library version numbers, API examples specific to a version.
**Check:** manifest version; if breaking change is plausible, grep usages.
**Likely fix:** update version reference; flag API examples that may need rewriting.

### 6. Env var renamed or removed

A doc that says "set `BETTER_AUTH_SECRET_KEY`" when the env validation source expects `BETTER_AUTH_SECRET`.

**Symptom in the doc:** env var names referenced in setup/config sections.
**Check:** env validation file (Zod schema, T3 env, etc.).
**Likely fix:** update the variable name.

### 7. "We don't have X yet" rotted positively

A doc that says "no test suite exists yet" when tests have since been added.

**Symptom in the doc:** "no X yet", "planned for", "not implemented", "future".
**Check:** is the missing thing now present?
**Likely fix:** remove the gap acknowledgment (often the corresponding instruction should be replaced with the current workflow).

### 8. File-extension or module-system claim

A doc that says "all server actions are in `*.server.ts`" when the project moved to plain `actions.ts` with `"use server"` directive.

**Symptom in the doc:** file naming conventions, extensions, file structure assumptions.
**Check:** spot-check by listing the directory or grepping the convention.
**Likely fix:** update the convention or remove the constraint.

## Parallelization

The drift checks are independent — Read the manifest, Grep multiple identifiers, list directories, all in one tool-call batch. Use parallel tool calls to keep the audit fast even on a large CLAUDE.md.

## What to do with drift findings

Drift findings are not the same as "cut me". They are:

1. **Always reported** — even if the user opts to skip pruning, they should know the doc has stale claims.
2. **Suggested fixes**, not auto-applied. The user may have context (a PR in flight, a partial migration) where the "wrong" claim is actually correct for a moment.
3. **Sometimes the fix is removal** — if the entire section was about a workflow that no longer exists, the section is both stale AND bloat: cut.
4. **Sometimes the fix is a rewrite** — if the section is genuinely useful but cites old artifacts, propose the rewrite.

Show drift findings as a distinct sub-section of the Quality Report, separate from the cut/keep recommendations. They cross-cut.
