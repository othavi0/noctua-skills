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

Skills split on one axis: who can invoke them. **User-invoked** skills run only
when you type them (e.g. `/dev-up`) — they orchestrate. **Model-invoked** skills
can be called by you *or* reached for automatically when the task fits — they hold
the reusable discipline.

### Engineering

**User-invoked**

- **[dev-up](./skills/engineering/dev-up/SKILL.md)** — `/dev-up <port>` — start this
  folder's dev server on a port, open one pinned browser tab, arm an error watcher,
  hand control back. Built for running several servers and tabs in parallel without
  disturbing them. First run on a machine bootstraps the claude-in-chrome connection
  itself.

**Model-invoked**

- **[claude-md-prune](./skills/engineering/claude-md-prune/SKILL.md)** — subtractive
  audit of `CLAUDE.md`: cut derivable content, flag drift (paths, commands, ADRs no
  longer matching the code). Triggers when you mention trimming or auditing `CLAUDE.md`.

### Writing

**Model-invoked**

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
```

## Notes

- `dev-up` needs the [claude-in-chrome](https://docs.claude.com/en/docs/claude-code) browser connection — on first run it walks through the one-time setup itself (`references/setup.md`), no separate command.
- Prefer to install by hand? Clone and copy a skill folder into `~/.claude/skills` (global) or `.claude/skills` (one project), then `/reload-skills`.

---

Part of the **noctua** toolset, alongside [agent-bar](https://github.com/othavi0/agent-bar). More at [othavio.com](https://othavio.com).
