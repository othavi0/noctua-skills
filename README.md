# noctua-skills

[![skills.sh](https://skills.sh/b/othavi0/noctua-skills)](https://skills.sh/othavi0/noctua-skills)

Six Claude Code skills I use every day, packaged to drop into any project. Each
one started as a bug I hit twice, and gets cut the moment it stops earning its
place.

A skill is a folder with a `SKILL.md`: YAML frontmatter plus instructions. Claude
Code reads the `description` to decide when to reach for it; the body guides the
run. Heavier material loads on demand from `references/`, so the trigger stays
cheap. Fork them. `dev-up`, `dev-up-agent-browser` and `browse-up` read their own folder
name to pick their cache, so keep those three names.

## Quickstart

```bash
npx skills@latest add othavi0/noctua-skills
```

Pick the skills and the agents you want them on. Add `--global` to install for
every project, or `-s dev-up` for just one. Then run `/reload-skills`, or restart
Claude Code.

Prefer to install by hand? Clone the repo and copy a skill folder into
`~/.claude/skills` (global) or `.claude/skills` (one project).

`dev-up`, `dev-up-agent-browser`, `browse-up`, `agent-desktop-omarchy` and `nuvem` are model-invoked. Type them as a slash command
(`/dev-up 3000`) or let Claude reach for them when the task fits the description.
`humanize-pt-br` runs only when you type it.

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

**[browse-up](./skills/engineering/browse-up/SKILL.md)** is `dev-up` rebuilt on
[Browse](https://opencode.ai/product/browse), after I read every past `dev-up`
session to see where the runs lost time. The server and the port-as-key stay.
The watcher is opt-in: the prompt hook already prints new log errors. A profile
per repo keeps the app directory, the dev command and the login endpoint, and
each worktree keeps its port, so a second run skips the discovery. The tab is now `dev-PORT`, an id the agent picks, so nothing
tracks a tab id, selects a browser or patches the tab title. A browser call
through Browse measured about 70 ms here, against about 850 ms through Claude in
Chrome. The biggest complaint in those sessions was login: the old skill told me
to type the test password, and I asked the agent to do it eight times. Now the
password goes from the project's seed to the page through a file the agent never
reads into the conversation, and a real account or a 2FA prompt goes back to me
with `handoff`. The skill and its references take 430 lines, against 412 in
`dev-up`, with the rules for driving the tab moved into `SKILL.md`. Needs the Browse extension
and its MCP server (`browse install -a claude`).

**[agent-desktop-omarchy](./skills/engineering/agent-desktop-omarchy/SKILL.md)** exists
because a Wayland desktop has one keyboard, and it is yours.
[agent-desktop](https://agent-browser.dev/desktop) reads and clicks a native app
through the accessibility bus, but on Hyprland it refuses keys, the pointer and a
screenshot of one window. The workaround, giving the app's window the focus and
typing, sent `81/9` plus Enter into the terminal I was working in. The skill
keeps agent-desktop for reading and clicking, and runs the app inside its own
[cage](https://github.com/cage-kiosk/cage) compositor, which has a keyboard of
its own: headless by default, so nothing shows on your screen, or as a window
when you want to watch. A small script types with `wtype` and takes screenshots
with `grim`, and it refuses every call whose socket is not a live cage or is
your own display. It renders on the GPU and sizes the output to the app, so a
screenshot shows the app the way you would see it. An idle headless session
measured 0% CPU. Tested with a Qt, a GTK and an Electron app. Omarchy or another
Hyprland desktop, with `agent-desktop`, `cage`, `wtype` and `grim`.

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
