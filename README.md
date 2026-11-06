# noctua-skills

[![skills.sh](https://skills.sh/b/othavi0/noctua-skills)](https://skills.sh/othavi0/noctua-skills)

Six Claude Code skills I use every day, packaged to drop into any project. Each
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

`dev-up`, `dev-up-agent-browser`, `nuvem` and `claude-md-prune` are model-invoked. Type them as a slash command
(`/dev-up 3000`) or let Claude reach for them when the task fits the description.
`mobile-up` and `humanize-pt-br` run only when you type them.

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

**[dev-up-agent-browser](./skills/engineering/dev-up-agent-browser/SKILL.md)**
is `dev-up` for agents that test on their own. Claude in Chrome drives one real
browser for everyone, at 0.5 to 1 s per action, so three agents testing three
apps fight over the same window and eat the RAM of a full browser each. This
skill keeps the server, the watcher and the port-as-key from `dev-up` and swaps
the tab for an [agent-browser](https://agent-browser.dev) session per port:
headless `chrome-headless-shell` at about 176 MB and 7 to 10 ms per click,
measured on a 16 GB machine. `dash` streams every session live in one page,
`show` turns a session into a real window with the login carried over, and
`hide` sends it back. Every call goes through one wrapper, because agent-browser
relaunches the browser whenever two calls disagree on their launch options, and
the window that comes back steals your focus. On Hyprland, one window rule
keeps the visible window from ever pulling you to its workspace.

**[mobile-up](./skills/engineering/mobile-up/SKILL.md)** exists because an Expo
app needs three things up at once and each one lies in its own way. The dev
server, Metro and the Android emulator all report "running" long before the
phone can use them: the app's env still says `localhost`, the port in LISTEN
belongs to another worktree, the bundle on air was built with yesterday's URL,
the emulator is showing someone else's session. One command brings the three up,
writes the machine's LAN IP into the app's env, waits for each piece to answer,
opens the app with a fresh bundle and waits for Metro to confirm delivery when
it can read Metro's log. The app opens in Expo Go, or in the project's
development build when the app depends on `expo-dev-client`. A port held by another checkout sends the skill to the
next free one, and it never kills a process it did not start. The evidence goes
into a question for you. Ten symptoms a device can show map to one check and
one fix each. When none matches, the skill stops and asks you for the error
text. Linux host, Android SDK for the emulator. iOS is out of scope.

**[nuvem](./skills/engineering/nuvem/SKILL.md)** exists because a build, an E2E
run and a before-and-after measurement do not fit on a laptop that is also running
everything else. It sends the task to a Claude Managed Agents session paid by the
monthly API credit, waits, fetches the patch and brings it back to review and
deliver through your normal flow. The credit is a hard ceiling: before opening a
session, the script adds what this month's sessions spent and the full cap of the
ones still running, and refuses when the new cap does not fit under the credit and
the Console spend limit. If it cannot read the spend, it refuses too. Per-repo
notes in `~/.config/nuvem/` record how to get each project running in a bare
container and every gate the local pipeline checks that the container cannot see,
so the next patch does not pass there and fail here. Linux, an API key, `curl` and `jq`.

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
PT-BR, Strunk, and a few open humanizer catalogues. The nine marks that kept
slipping into published PRs sit in `SKILL.md` itself, and `scripts/scan.py`
catches the mechanical ones (dashes, arrows, "não é X. É Y", bold labels) before
the text goes out. It refuses to invent a fact the source does not carry, and
that includes hours spent and a "never" softened to "rarely". Feed it a sample
of your own writing and it calibrates the voice against that instead of the
defaults.

---

Part of the **noctua** toolset, alongside
[omarchy-agent-bar](https://github.com/othavi0/omarchy-agent-bar).
