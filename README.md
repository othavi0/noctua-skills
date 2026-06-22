# noctua-skills

Claude Code skills I actually use, packaged to drop into any project. Curated,
not exhaustive: each one earns its place or it is cut.

A skill is a folder with a `SKILL.md` (YAML frontmatter + instructions). Claude
Code reads the `description` to decide when to trigger; the body guides the run.
Heavier material loads on demand from a `references/` folder, so the trigger
stays cheap.

## The skills

| skill | what it does | invoke |
| --- | --- | --- |
| **claude-md-prune** | Subtractive audit of `CLAUDE.md`: cuts derivable content and flags drift (paths, commands, ADRs no longer matching the code), following the Boris Cherny / Anthropic filter — *"would removing this cause Claude to make mistakes? If not, cut it."* | auto, when you mention trimming or auditing `CLAUDE.md` |
| **dev-up** | Starts the current folder's dev server on a chosen port, opens one browser tab pinned to that port, and arms an error watcher — then hands control back. Built for running several servers and tabs in parallel without disturbing them. | `/dev-up <port>` |
| **dev-up-setup** | One-time setup that makes `dev-up` work on a machine: connects the claude-in-chrome browser, names the device, verifies. | `/dev-up-setup` |
| **humanize-pt-br** | Removes AI tells from Brazilian-Portuguese prose — 30+ verified patterns (inflated vocabulary, formulaic triggers, impersonal passive, negative parallelism, sycophancy). Wikipedia's *Signs of AI writing* adapted to PT-BR, plus Strunk. | auto, when editing PT-BR prose |

## Install

Skills live in `~/.claude/skills` (global, every project) or `.claude/skills`
(one project). Copy the ones you want:

```bash
git clone https://github.com/othavi0/noctua-skills

# all of them, globally
cp -r noctua-skills/skills/{claude-md-prune,dev-up,dev-up-setup,humanize-pt-br} ~/.claude/skills/

# or just one
cp -r noctua-skills/skills/dev-up ~/.claude/skills/
```

Then run `/reload-skills` (or restart Claude Code). Invoke a skill by its slash
command, or let model-invocable ones trigger on their own.

## Structure

```
skills/
  claude-md-prune/   SKILL.md + references/
  dev-up/            SKILL.md + references/
  dev-up-setup/      SKILL.md
  humanize-pt-br/    SKILL.md + patterns-pt-br.md
```

## Notes

- `dev-up` needs the [claude-in-chrome](https://docs.claude.com/en/docs/claude-code) browser connection — run `/dev-up-setup` once before the first `/dev-up`.
- `dev-up-setup` is user-invoked only (`disable-model-invocation`); the model never runs it on its own.
- `humanize-pt-br` is scoped to Read / Write / Edit and is Portuguese-only by design.

---

Part of the **noctua** toolset, alongside [agent-bar](https://github.com/othavi0/agent-bar). More at [othavio.com](https://othavio.com).
