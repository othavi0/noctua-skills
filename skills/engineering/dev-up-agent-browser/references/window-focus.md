# Window focus

Read this when the user wants the `show` window to stay out of their way: the agent keeps working
in it while they use another workspace.

Every window the skill opens carries the class `agent-browser` (Wayland app id, X11 `WM_CLASS`),
set through `--class=agent-browser` on every call. A window manager rule on that class decides
focus. Two behaviours make a window grab attention: focus when it maps, and focus when it asks to
be activated. The rule turns off both.

## Hyprland (Omarchy)

Omarchy turns `misc:focus_on_activate` on for every window, so any activation request pulls the
user to the window's workspace. Add to `~/.config/hypr/hyprland.lua`, after Omarchy's defaults:

```lua
o.window("^agent-browser$", { no_initial_focus = true, focus_on_activate = false })
```

Then `hyprctl reload` and `hyprctl configerrors`, which prints nothing when the rule is valid. Plain
Hyprland without Omarchy's `o.window` helper takes the same two rules in its own window rule
syntax; read the Hyprland wiki for the version installed.

Measured on Hyprland 0.57.1: the window opened without focus in 3 of 3 launches, and the focus
stayed put across 174 samples during 20 actions (click, fill, screenshot, viewport). Hyprland's
focus also follows the mouse (`input:follow_mouse = 1`): moving the cursor over the window focuses
it, which is the user's own move.

## Checking it

`hyprctl clients` lists the window with `class: agent-browser`. A window there with another class
came from a call outside `S ab PORT`, which relaunched the browser without its options: close the
session and open it again through `S ab PORT`.
