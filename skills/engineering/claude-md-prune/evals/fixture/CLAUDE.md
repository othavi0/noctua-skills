# fixture-shop

## Stack

- Frontend: Next.js 16, React 19
- DB: PostgreSQL + Drizzle ORM 0.45
- Auth: Better Auth 1.6
- Lint: Biome 2.4

## Structure

```
apps/
  web/          Frontend
  api/          Backend
  worker/       Job queue
packages/
  db/           Database client + schema
```

## Commands

- `bun run dev` starts the dev server
- `bun run build` builds for production
- `bun run lint` runs the linter
- Single test: `bun test --filter <name> apps/api` from the repo root. Plain `bun run test` runs the 12-minute e2e suite.
- After `bun db:push`, always run `bun db:apply-triggers`. drizzle-kit does not generate triggers.
- After editing the schema, run `bun db:generate`.

## Where things live

- Stripe webhooks are handled in `apps/worker/src/inbound/`, not in `apps/api`. Grepping `stripe` lands on the dead copy in `legacy/stripe/` first.

## Code style

- Use TypeScript with strict mode
- Prefer const over let
- Write clean, readable code
- Handle errors properly

## Auth invariants

- `apps/web` never imports from `apps/api/src`. They share types through `packages/db` only.
- Never set the session cookie domain to `.fixture.shop`. Each subdomain is a separate trust zone.

## Gotchas

- `db.execute()` returns timestamps as strings in Drizzle 0.45. Coerce with `toDate()` at the boundary.

## Getting started

1. Install Bun
2. Copy `.env.example` to `.env`
3. Run `bun install`

## Preferences

- I prefer succinct responses in Portuguese.
