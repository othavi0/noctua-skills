# Project notes

Each repo gets two notes in `~/.config/nuvem/projects/`, named after the repo folder:

- `<repo>.md` goes to the cloud, prepended to every brief for that repo. It is the **recipe** that gets the repo running in a bare container.
- `<repo>-local.md` stays here. It says how to apply the patch and deliver it in this repo.

They live outside the skill, so an update never erases them, and they hold what no config file confesses. Write them on the first run for a repo, and add to them every time a cloud patch fails here for a reason the container could not see.

## Writing `<repo>.md`

Read the repo's README, `CLAUDE.md` or `AGENTS.md`, the package manifest, the CI config and the env schema. Then write, as steps the cloud agent runs:

1. The toolchain at the pinned version (`packageManager`, `.nvmrc`, `.tool-versions`, `rust-toolchain`): how to install that exact version in an Ubuntu 24.04 container.
2. Dependencies: the install command.
3. Services the tests need. The container ships PostgreSQL 16 and Redis 7, installed and stopped; Docker is limited. Say how to start them and create the database.
4. Env: every variable the app or tests read, filled with throwaway values generated in the container. Production secrets never go in.
5. Data: migrations, seeds, test factories.
6. Browsers: Playwright needs the Chromium its version pins, and the CDN may not resolve; point at the copy under `/opt/pw-browsers` with a symlink.

Then a section **What the local pipeline checks that the container cannot see**: every gate that runs here and differs there. Common ones:

- tests that pass in the container only because it has something the local run lacks (a file store, a service, a port);
- absolute URLs or ports baked into env that differ between the container and the local test runner;
- size or performance budgets measured against the current main, which moves while the session runs;
- naming conventions the repo's linters or reviewers enforce.

## Writing `<repo>-local.md`

- How a worktree is created and prepared in this repo, and what must exist before `git am` (dependencies, local env).
- The cheap checks to run after applying, with memory caps if the machine needs them; the heavy ones stay with the repo's pipeline.
- How delivery works: PR, merge queue, release notes. Point at the repo's own docs where they say it, rather than restating them.

## Example

A web monorepo with a pinned package manager, Postgres and browser tests ended up with these in `<repo>.md`: the package manager installed from npm at the pinned version; Postgres started locally with a throwaway connection string; the auth secret from `openssl rand -hex 32`; email and object storage left empty; the local E2E runs without a file store and on a different port than the env's base URL, so tests that upload files or open absolute app links move to unit tests or use the page's origin; the bundle-size budget re-measured against the current main with headroom.
