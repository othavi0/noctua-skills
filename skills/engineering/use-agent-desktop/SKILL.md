---
name: use-agent-desktop
description: >-
  Drives a native desktop app on Wayland with agent-desktop for reading and clicking, and a small
  cage shell for the parts agent-desktop refuses there (keyboard, screenshots), without touching
  the user's focus, cursor or keyboard. Use for `/use-agent-desktop`, when asked to test, drive or
  screenshot a desktop app (Qt, GTK, Electron) in the background or for evidence, or when keys
  sent to a window landed in the user's own window. Not for a web page (agent-browser,
  dev-up-agent-browser) or for changing desktop settings (omarchy).
# argument-hint and allowed-tools are Claude Code fields, not part of the Agent Skills spec.
argument-hint: "[name] [-- command]"
allowed-tools:
  - Bash(bash ${CLAUDE_SKILL_DIR}/scripts/cage.sh *)
---

# use-agent-desktop

[agent-desktop](https://agent-browser.dev/desktop) reads an app's controls and clicks them through
the accessibility bus. On a Wayland session outside GNOME it refuses the rest: `press`, pointer
input, a screenshot of one window, `focus-window`. This skill fills that gap with
[cage](https://github.com/cage-kiosk/cage), a compositor that runs one app. A Wayland desktop has
one keyboard and one cursor, and they belong to the user. A cage has a keyboard of its own, so
keys sent to a session cannot reach the user's windows.

Load the **agent-desktop** skill first. It owns `snapshot`, refs, `click`, the retry rules and the
error codes, and this file does not repeat them.

In this file `C start NAME` is notation for the Bash call
`bash ${CLAUDE_SKILL_DIR}/scripts/cage.sh start NAME`. Type the whole path on every call, so
`allowed-tools` matches. Each command prints its verdict first (`STARTED`, `TYPED`, `SHOT`,
`REFUSED`). `C` alone lists the commands. `NAME` is a label you choose, such as `calc`.

## The one rule: keys go through `C`

Never run `wtype` yourself, and never give a window of the user's desktop the focus to type into
it. `wtype` types into whichever compositor `WAYLAND_DISPLAY` names. With the user's value, the
text and its Enter land in the window the user is working in. `C type`, `C key` and `C shot`
refuse with `REFUSED reason=...` unless the session's socket belongs to a live cage and differs
from the caller's display.

Needs `agent-desktop`, `cage`, `wtype` and `grim` on `PATH`, and a Wayland session. `wlr-randr` is
optional: it sizes a headless session. On Omarchy, install a missing package with
`omarchy pkg add cage wtype grim wlr-randr`.

## Steps

1. **Start.** `C start NAME --size WxH -- CMD [ARGS]` runs the app headless: nothing shows on the
   user's screen. Add `--visible` before `--` only when the user asks to watch or to use the app
   too. Give `--size` the window size the app was drawn for, such as `420x640` for a calculator:
   see [Rendering](#rendering). Done when it prints `STARTED`. On `FAILED`, read the log tail it
   prints.
2. **Look.** `C shot NAME FILE` saves a PNG of the session. Read the PNG. The picture is the only
   proof of what the app shows, because many apps leave their display out of the accessibility
   tree.
3. **Read and click.** `agent-desktop snapshot --app APP -i --compact` lists the controls with
   their refs, and `agent-desktop click REF` clicks one. `APP` is the name
   `agent-desktop list-apps` prints. Prefer a ref action to a key wherever both work: it needs no
   focus inside the app.
4. **Type.** `C type NAME 'text'` types text. `C key NAME Return` presses keys: an xkb name
   (`Return`, `Escape`, `BackSpace`, `Tab`), one character, or a combination such as `ctrl+a`.
5. **Verify.** After each action that matters, run `C shot` again and read the PNG. A click
   answers `delivered_unverified`: the picture says whether it landed.
6. **Stop.** `C stop NAME` ends the cage and the app. Stop every session you started before the
   final report, unless the user asked to keep it. `C status` lists what still runs.

Done when the screenshots show the result the task asked for and `C status` prints `NONE`, or only
the sessions the user asked to keep.

## Rendering

A screenshot is evidence only when the app looks the way a user sees it. Check these before you
report a layout as broken.

- **Size.** cage stretches the app to its whole output. A headless output is 1280x720, so an app
  drawn for a narrow window comes out wide, with stretched buttons. `--size WxH` gives the output
  the app's own shape. A visible session takes the size from the window. A headless session needs
  `wlr-randr`. Without it, `start` prints `size=1280x720` and a `warn` line: report that the
  screenshot is stretched, or use `--visible --size WxH`.
- **Renderer.** The cage renders on the GPU when wlroots finds one, and the session's log then
  has `Creating GLES2 renderer`. With `WLR_RENDERER=pixman` the cage draws on the CPU and gives
  the app no GPU buffers, so an app that needs the GPU can draw without its effects. Force
  `pixman` only on a machine with no GPU, and say so next to each screenshot.
- **First frame.** Take the screenshot after the app has drawn. When a shot shows an empty or
  half-drawn window, wait for a control with `agent-desktop wait --element` and shoot again.

## Evidence

Save the screenshots that prove a result where the task keeps its evidence, not in the state
directory: `~/.cache/use-agent-desktop/` is a cache. Name each file after what it proves. Report
the absolute path of each file.

## Gotchas

- An idle headless session measured 0% CPU and 92 MB for the cage on the GPU, and 0% CPU and
  22 MB with `WLR_RENDERER=pixman`. A visible one measured 5.4% CPU and 93 MB. The app's own
  memory comes on top. Stop a session when its check ends.
- A Qt app joins the accessibility bus only when `QT_LINUX_ACCESSIBILITY_ALWAYS_ON=1` is set at
  launch. `C start` sets it. A Chromium or Electron app needs its own flag: see
  `agent-desktop skills get agent-desktop-linux references/troubleshooting.md`.
- Two sessions of the same app share one name on the accessibility bus, and `agent-desktop` cannot
  tell them apart. Run one session per app when the task needs clicks.
- A click by screen coordinate has no command here. `agent-desktop` refuses pointer input on
  Wayland, and `wtype` sends keys only. Reach the control with a ref, or with `Tab` and `Return`.
- `--visible` opens a normal window whose class is `wlroots`. With that window focused, the user's
  keyboard and mouse work inside it too. On Hyprland, `C start` asks for a floating window that
  does not take focus.
- An app the user already has open cannot move into a cage. For that window, use only
  `agent-desktop` ref actions and no keys.
