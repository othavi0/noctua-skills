# Interacting with and debugging the tab

After [`SKILL.md`](../SKILL.md) hands control back, drive and debug the app through `TARGET_TAB_ID`
this way.

- Read text before you take a screenshot. To inspect or click, use `find` or `read_page`
  (`filter=interactive`), which return refs. A screenshot costs about 1.5k tokens, covers only the
  viewport and has no refs, so keep it for layout, CSS and render checks.
- The first navigation to a route starts an on-demand compile (Vite, Turbopack, webpack). While it
  runs, the renderer is busy and `screenshot` and other CDP actions time out with "renderer busy".
  Wait for the route to settle or retry once, and read text or `javascript_tool` in the meantime.
  When a screenshot or click times out on a settled route, read `document.visibilityState`.
  `hidden` means the tab sits behind another one and the browser throttles it, so ask the user to
  bring it forward.
- Click through a ref from `read_page` or `find`, never a pixel coordinate. Coordinates drift after
  a navigation, a modal, a list re-render or a compile, and the click lands on nothing. A confirm
  or destructive button always gets a `find` ref first. After a click that changes the DOM, read
  the refs again.
- Chain predictable steps in one `browser_batch`: `navigate` and `read_page`, `form_input` across
  several refs, or click, type and press. A batch does not pass one action's output to the next,
  so a step that needs a ref you have not seen yet goes in its own call. A batch skips the
  permission prompt only when every action in it is read-only, and `navigate` is not.
- For a breakpoint, call `resize_window` and then check `window.innerWidth` and `innerHeight` with
  `javascript_tool`. On Hyprland a request for 390px left the window at 2106px while the tool
  reported success. When the resize does not stick, measure the width with a same-origin iframe of
  the target width inside this tab.
- The Monitor watches the server log only. Client errors (React, a `fetch` 4xx or 5xx, a browser
  exception) stay in the browser console, and nothing notifies you about them. Run
  `read_console_messages` with `onlyErrors` and `read_network_requests` when the screen looks
  broken or an action fails.
- A screenshot right after a programmatic scroll (`scrollIntoView` through `javascript_tool`) can
  capture the page still at the top. Read `window.scrollY` or `find` the target again before you
  take it.
- `javascript_tool` reads `localStorage`, `sessionStorage` and cookies without the HttpOnly flag.
  An HttpOnly session cookie needs a CDP debug port, which this setup does not have.
