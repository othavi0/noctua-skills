# First-run setup: connect the browser

## ToolSearch returns no `mcp__claude-in-chrome__*` tool

The extension is not connected to this session, which says nothing about whether this machine has
Chrome. Ask the user to run `/chrome` and pick Reconnect, then load the tools again. Go on to the
next section only when `list_connected_browsers` then returns no browser or errors.

## `list_connected_browsers` returns no browser

The claude-in-chrome extension is not installed, not signed in, or not paired on this machine. Each
computer needs this once.

1. Install. The user installs Claude in Chrome by Anthropic's current docs
   (https://code.claude.com/docs/en/chrome) and signs in with the same Claude account. The
   extension must run in a browser on the machine that runs the dev server, because `localhost`
   resolves only there.
2. Pair. Run `switch_browser`. It sends a connection request to every browser with the extension
   and waits up to 2 minutes for the user to click Connect, where they can also name the browser.
   With no browser paired it can fail at once with "No other browsers available to switch to".
   That is not final: ask the user to open the browser and click Connect in the extension, then
   call `list_connected_browsers` again until the device shows up.
3. Return to [`SKILL.md`](../SKILL.md) step 4.1. It selects the browser and writes the cache, so the
   next `/dev-up` does not ask.
