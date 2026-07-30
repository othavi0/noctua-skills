# First-run setup — connect the browser

Reach here from [`SKILL.md`](../SKILL.md) step 4 when `list_connected_browsers` returns **no
browsers** (or the call errors): the claude-in-chrome extension isn't installed, isn't signed in, or
no browser is paired on this machine. This is a once-per-machine bootstrap — after it, the normal
selection flow binds and caches the browser, and you never come back here.

## 1. Install and sign in

`dev-up` drives the browser through the **claude-in-chrome** extension (and its MCP server). If it's
not installed: install "Claude in Chrome" from the official source and sign in with the **same Claude
account**, following Anthropic's current install docs rather than guessing (the flow changes). The
extension must run in the browser **on the machine where the dev server runs** — `localhost` only
resolves there.

## 2. Pair this browser

Run `switch_browser`. It broadcasts a connection request to every browser with the extension and
waits (up to 2 min) for the user to click **Connect** in the one they want — and on that screen they
can **name it** (e.g. `"work Brave"`). With **zero** browsers paired it can instead fail
immediately with "No other browsers available to switch to" — that's not a dead end: ask the user
to open the browser and click **Connect** in the extension, then re-poll `list_connected_browsers`
(cheap) until the device shows up. Don't treat the first error as final. Naming is optional: `dev-up` caches the **deviceId** as the
durable key (the display name often reverts to a generic `"Browser 1/2/3"`), so an unnamed device is
fine.

## 3. Back to selection

Once `list_connected_browsers` shows the browser, return to [`SKILL.md`](../SKILL.md) step 4 — the
normal flow selects it and writes the per-machine cache (`deviceId` + `name`), so the next `/dev-up`
won't ask. Run this bootstrap once on **each computer**.
