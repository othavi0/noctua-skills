# noctua-skills

[![skills.sh](https://skills.sh/b/othavi0/noctua-skills)](https://skills.sh/othavi0/noctua-skills)

Four Claude Code skills I use every day, packaged to drop into any project. Each
one started as a bug I hit twice, and gets cut the moment it stops earning its
place.

A skill is a folder with a `SKILL.md`: YAML frontmatter plus instructions. Claude
Code reads the `description` to decide when to reach for it; the body guides the
run. Heavier material loads on demand from `references/`, so the trigger stays
cheap. Fork them and rename them. Nothing here depends on the folder name.

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

**[dev-up](./skills/engineering/dev-up/SKILL.md)** starts when dev servers trip
over each other. Run a few projects at once and the terminals blur together: which
tab is which port, who threw that error. It starts the server on a port you name,
opens one pinned browser tab, arms an error watcher whose filter you widen the
first time a benign error wakes you, and hands control back without disturbing
anything else already running. In a fresh git worktree it checks for missing
`node_modules` first, because a launch that dies on `esbuild: command not found`
costs a full turn. Needs the
[claude-in-chrome](https://code.claude.com/docs/en/chrome) browser connection,
and walks through that one-time setup itself on first run.

**[mobile-up](./skills/engineering/mobile-up/SKILL.md)** exists because an Expo
app needs three things up at once and each one lies in its own way. The dev
server, Metro and the Android emulator all report "running" long before the
phone can use them: the app's env still says `localhost`, the port in LISTEN
belongs to another worktree, the bundle on air was built with yesterday's URL,
the emulator is showing someone else's session. One command brings the three up,
writes the machine's LAN IP into the app's env, waits for each piece to answer,
opens the app with a fresh bundle and waits for Metro to confirm delivery when
it can read Metro's log. A port held by another checkout sends the skill to the
next free one, and it never kills a process it did not start. The evidence goes
into a question for you. Nine symptoms a device can show map to one check and
one fix each. When none matches, the skill stops and asks you for the error
text. Linux host, Android SDK for the emulator. iOS is out of scope.

**[claude-md-prune](./skills/engineering/claude-md-prune/SKILL.md)** runs because
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

---

Part of the **noctua** toolset, alongside
[omarchy-agent-bar](https://github.com/othavi0/omarchy-agent-bar).
