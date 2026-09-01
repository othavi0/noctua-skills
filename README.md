# noctua-skills

[![skills.sh](https://skills.sh/b/othavi0/noctua-skills)](https://skills.sh/othavi0/noctua-skills)

Three Claude Code skills I use every day, packaged to drop into any project. Each
one came out of a real friction, and gets cut the moment it stops earning its
place.

A skill is a folder with a `SKILL.md`: YAML frontmatter plus instructions. Claude
Code reads the `description` to decide when to reach for it; the body guides the
run. Heavier material loads on demand from `references/`, so the trigger stays
cheap. Fork them, rename them, make them yours.

## Quickstart

```bash
npx skills@latest add othavi0/noctua-skills
```

Pick the skills and the agents you want them on. Add `--global` to install for
every project, or `-s dev-up` for just one. Then run `/reload-skills`, or restart
Claude Code.

Prefer to install by hand? Clone the repo and copy a skill folder into
`~/.claude/skills` (global) or `.claude/skills` (one project).

Every skill is model-invoked. Type it as a slash command (`/dev-up 3000`) or let
Claude reach for it when the task fits the description.

## Engineering

**[dev-up](./skills/engineering/dev-up/SKILL.md)** exists because dev servers trip
over each other. Run a few projects at once and the terminals blur together: which
tab is which port, who threw that error. It starts the server on a port you name,
opens one pinned browser tab, arms an error watcher that learns to ignore benign
noise, and hands control back without disturbing anything else already running. In
a fresh git worktree it checks for missing `node_modules` first, because a launch
that dies on `esbuild: command not found` costs a full turn. Needs the
[claude-in-chrome](https://docs.claude.com/en/docs/claude-code) browser connection,
and walks through that one-time setup itself on first run.

**[claude-md-prune](./skills/engineering/claude-md-prune/SKILL.md)** exists because
`CLAUDE.md` bloats into noise. Project memory grows by accretion: paths that moved,
commands that changed, advice the code already enforces. The skill runs the Boris
Cherny / Anthropic filter, *"Would removing this cause Claude to make mistakes?" If
not, cut it*, and flags the lines that drifted out of sync with the code.

## Writing

**[humanize-pt-br](./skills/writing/humanize-pt-br/SKILL.md)** exists because
Portuguese prose from an LLM carries tells: inflated vocabulary, negative
parallelism, sycophancy, em-dashes everywhere. The catalogue holds 49 marks
across six families, built from Wikipedia's *Signs of AI writing* adapted to
PT-BR, Strunk, and a few open humanizer catalogues. Every rewrite runs a
four-step engine (detect, draft, self-audit, deliver) and refuses to invent a
fact the source does not carry. Feed it a sample of your own writing and it
calibrates the voice against that instead of the defaults.

## Runbooks

[docs/](./docs/README.md) holds operational notes that are **not** agent skills:
reinstall recipes, desktop workarounds, how do I do this again in six months.
Right now that is [DaVinci Resolve on
Omarchy](./docs/omarchy/davinci-resolve.md), covering the AUR manual zip, the
Intel + NVIDIA hybrid GPU wrapper, the Super+Space `.desktop`, and the lockfile
and zombie fixes.

---

Part of the **noctua** toolset, alongside
[agent-bar](https://github.com/othavi0/agent-bar). More at
[othavio.com](https://othavio.com).
