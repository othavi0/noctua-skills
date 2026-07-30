# Cut Criteria — what gets removed

Content categories that Claude can infer from the code or from generic language knowledge. Cut aggressively.

When showing the user **why** a section is being cut, cite the specific category here so the reasoning is consistent across the audit.

## Contents

1. Stack / dependency lists
2. Directory structure trees
3. Command listings
4. Environment variable lists
5. Architecture explainers
6. Per-folder descriptions
7. Tutorials and onboarding instructions
8. Generic best practices Claude already knows
9. Generic linter rules
10. Long verbose explanations

Plus the summary heuristic at the end.

## 1. Stack / dependency lists

A list of frameworks, libraries, and versions used by the project.

**Why cut:** the manifest file (`package.json`, `Cargo.toml`, `pyproject.toml`, etc.) is the authoritative source. Claude can read it in 0.5s. The doc copy goes stale and creates two competing sources of truth.

**Looks like:**

```markdown
## Stack
- Frontend: Next.js 16, React 19
- Backend: Node 22 + Express 5
- DB: PostgreSQL 16 + Drizzle ORM 0.45
- Auth: Better Auth 1.6
- Lint: Biome 2.4
```

**Exception:** if the doc explains *why* a non-standard choice was made (e.g., "we use library X over the more common Y because Y has bug Z"), that rationale is non-obvious — convert to a short gotcha and keep it.

## 2. Directory structure trees

ASCII tree of the project layout.

**Why cut:** `ls`/`tree`/`find` give the current state instantly. Trees in docs rot the moment someone adds a folder. The folder names themselves usually convey meaning.

**Looks like:**

```markdown
## Structure
apps/
  web/          Frontend
  api/          Backend
  worker/       Job queue
packages/
  shared/       Shared types
  ui/           Component library
```

**Exception:** if there's a non-obvious convention encoded in folder names (e.g., underscore prefix means "private to this route" in Next.js App Router), keep that convention as a one-liner. Cut the tree.

## 3. Command listings

A block listing all available scripts/tasks.

**Why cut:** `package.json` scripts, `Cargo.toml` targets, `Makefile` rules, etc. are the source. Verbose duplication in CLAUDE.md falls behind reality quickly.

**Looks like:**

```markdown
## Commands
bun install    Install dependencies
bun run dev    Start dev server
bun run build  Build for production
bun run test   Run tests
bun run lint   Lint
```

**Exception:** keep a command **only if** it carries non-obvious context (order matters, side effects, must-do-after). Example to keep: "After `bun db:push`, always run `bun db:apply-triggers` — drizzle-kit does not generate triggers." That's a gotcha, not a listing.

## 4. Environment variable lists

Enumeration of every env var the project reads.

**Why cut:** the env validation file (Zod schema, T3 env, dotenv-vault config) is the source. Duplicated in CLAUDE.md it falls behind on every env addition.

**Looks like:**

```markdown
## Environment variables
- DATABASE_URL — connection string
- BETTER_AUTH_SECRET — min 32 chars
- RESEND_API_KEY — email provider
- GOOGLE_CLIENT_ID — OAuth
... etc
```

**Exception:** keep env-related **gotchas**. Example: "`SUPABASE_SERVICE_ROLE_KEY` bypasses RLS — do not expose to client" is a security gotcha worth keeping. Cut the list, keep the warning.

## 5. Architecture explainers

Long prose describing how the system works, the request flow, the data flow.

**Why cut:** reading the source code is more reliable than reading a written summary. Architecture descriptions in docs are notorious for drifting; they're the first thing to rot after a refactor.

**Looks like:**

```markdown
## Architecture
The frontend sends requests to the API gateway, which routes them
to the appropriate service. Authentication is handled at the gateway
level via JWT tokens. The database is accessed through a connection
pool managed by the ORM layer. Background jobs are dispatched to ...
```

**Exception:** if there's a **specific non-obvious decision** (e.g., "the API gateway intentionally does NOT proxy WebSocket connections — those go direct to the realtime service"), keep that as a gotcha. Cut the rest.

## 6. Per-folder descriptions

A table or list explaining what each folder/package does.

**Why cut:** identical to directory trees — derivable from the structure and the contained code. The folder name usually does the work.

**Looks like:**

```markdown
| Folder | Purpose |
|---|---|
| apps/web | Main frontend |
| apps/api | REST API |
| packages/db | Database client + schema |
| packages/ui | Shared components |
```

## 7. Tutorials and onboarding instructions

Step-by-step "getting started" content.

**Why cut:** belongs in `README.md` or `docs/`. CLAUDE.md is for things that affect how Claude operates on the code, not for instructing humans.

**Looks like:**

```markdown
## Getting started
1. Install Bun: `curl -fsSL https://bun.sh/install | bash`
2. Clone the repo: `git clone ...`
3. Copy `.env.example` to `.env`
4. Run `bun install`
5. Start the dev server with `bun run dev`
```

## 8. Generic best practices Claude already knows

Conventions that are language- or framework-standard and Claude was trained on.

**Why cut:** they consume tokens without changing behavior. Claude already knows them. Every line not pulling its weight dilutes the lines that are.

**Looks like:**

```markdown
## Code style
- Use TypeScript with strict mode
- Prefer const over let
- Use async/await over .then()
- Write clean, readable code
- Follow REST conventions for API endpoints
- Handle errors properly
- Write tests
```

**Exception:** convention that **differs** from the language/framework default. Example to keep: "We prefer `for...of` over `.forEach()` in hot paths — V8 deoptimization observed in production logs." That's a project-specific decision.

## 9. Generic linter rules

Restating what the linter config already enforces.

**Why cut:** the linter exists. The rules are in `biome.json`/`.eslintrc`/`rustfmt.toml`/etc. Duplicating them in prose adds noise without adding enforcement.

**Looks like:**

```markdown
## Linting
- No unused imports
- No unused variables
- No console.log
- No any types
- Prefer template literals over string concatenation
```

**Exception:** if the rule has a project-specific **why** (e.g., "no `console.log` because our log shipper expects structured JSON from `logger.*`"), keep the why as a one-liner.

## 10. Long verbose explanations

A paragraph where a one-liner would do.

**Why cut:** "dense is better than verbose" (Anthropic guidance). If the same content can be expressed in one sentence with the same effect on Claude's behavior, the paragraph is bloat.

**Looks like:**

```markdown
## Authentication
We use Better Auth, a modern authentication library that handles
session management, OAuth providers, email verification, and password
resets. The configuration lives in `packages/auth/` and is consumed
by the API layer. Sessions are stored in the database with a TTL of
30 days. Cookies are HTTP-only and use the `secure` flag in production.
```

→ would be the same useful information as:

```markdown
- Auth: Better Auth in `packages/auth`. Session TTL 30 days, HTTP-only cookies.
```

## Summary heuristic

For any candidate line/section, ask:

> **"If I deleted this line, would Claude make a mistake it wouldn't make otherwise?"**

If no → cut.
If unsure → ask the user "did this line ever fix a real bug?" before cutting.
If yes → keep (see `keep-criteria.md`).
