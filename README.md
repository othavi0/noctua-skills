# noctua-skills

[![skills.sh](https://skills.sh/b/othavi0/skills)](https://skills.sh/othavi0/skills)

A small set of Claude Code skills I actually use, packaged to drop into any
project. Curated, not exhaustive — each one earns its place or it gets cut.

A skill is a folder with a `SKILL.md`: YAML frontmatter plus instructions. Claude
Code reads the `description` to decide when to reach for it; the body guides the
run. Heavier material loads on demand from a `references/` folder, so the trigger
stays cheap. They're small, composable, and model-agnostic — fork them, rename
them, make them yours.

## Quickstart

1. Install with the [skills.sh](https://skills.sh) CLI:

   ```bash
   npx skills@latest add othavi0/skills
   ```

2. Pick the skills and the agents you want them on. Add `--global` to install for
   every project, or `-s dev-up` for just one.

3. Run `/reload-skills` (or restart Claude Code).

4. Invoke by slash command, or let the model-invoked ones trigger on their own.

## Why these exist

Each one came out of a real friction, not a "wouldn't it be neat" idea.

**Dev servers that trip over each other.** Run a few projects at once and the
terminals blur together — which tab is which port, who threw that error. `dev-up`
pins one browser tab to a chosen port, arms an error watcher, and stays out of the
way of everything else already running.

**`CLAUDE.md` that bloats into noise.** Project memory grows by accretion: paths
that moved, commands that changed, advice the code already enforces.
`claude-md-prune` runs the Boris Cherny / Anthropic filter — *"would removing this
cause Claude to make mistakes? If not, cut it"* — and flags the lines that drifted
out of sync with the code.

**Prose that reads like a machine wrote it.** Portuguese text from an LLM carries
tells: inflated vocabulary, negative parallelism, sycophancy, em-dashes
everywhere. `humanize-pt-br` strips 30+ verified patterns — Wikipedia's *Signs of
AI writing* adapted to PT-BR, plus Strunk.

## Reference

Every skill here is **model-invoked**: type it as a slash command (`/dev-up 3000`)
or let Claude reach for it on its own when the task fits its description.

### Engineering

- **[dev-up](./skills/engineering/dev-up/SKILL.md)** — `/dev-up <port>`, or triggers
  when you ask to start, view, or monitor this folder's dev server — starts it on a
  port, opens one pinned browser tab, arms an error watcher, hands control back.
  Built for running several servers and tabs in parallel without disturbing them.
  First run on a machine bootstraps the claude-in-chrome connection itself.
- **[claude-md-prune](./skills/engineering/claude-md-prune/SKILL.md)** — subtractive
  audit of `CLAUDE.md`: cut derivable content, flag drift (paths, commands, ADRs no
  longer matching the code). Triggers when you mention trimming or auditing `CLAUDE.md`.

### Writing

- **[humanize-pt-br](./skills/writing/humanize-pt-br/SKILL.md)** — remove AI tells from
  Brazilian-Portuguese prose: 30+ verified patterns (inflated vocabulary, impersonal
  passive, negative parallelism, sycophancy). Scoped to Read / Write / Edit, and
  Portuguese-only by design.

## Structure

```
skills/
  engineering/
    claude-md-prune/   SKILL.md + references/
    dev-up/            SKILL.md + references/
  writing/
    humanize-pt-br/    SKILL.md + references/
docs/                  Operational runbooks (not skills)
  omarchy/
    davinci-resolve.md Install / hybrid GPU / launcher on Omarchy
```

## Useful docs

Runbooks that are **not** agent skills — reinstall recipes, desktop workarounds,
“how do I do this again in six months”:

- **[docs/](./docs/README.md)** — index  
- **[DaVinci Resolve on Omarchy](./docs/omarchy/davinci-resolve.md)** — AUR manual zip,
  Intel+NVIDIA hybrid GPU, wrapper + Super+Space `.desktop`, lockfile/zombie fixes

## Notes

- `dev-up` needs the [claude-in-chrome](https://docs.claude.com/en/docs/claude-code) browser connection — on first run it walks through the one-time setup itself (`references/setup.md`), no separate command.
- Prefer to install by hand? Clone and copy a skill folder into `~/.claude/skills` (global) or `.claude/skills` (one project), then `/reload-skills`.

---

Part of the **noctua** toolset, alongside [agent-bar](https://github.com/othavi0/agent-bar). More at [othavio.com](https://othavio.com).
