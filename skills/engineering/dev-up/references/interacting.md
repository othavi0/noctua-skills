# Interacting with and debugging the tab

After [`SKILL.md`](../SKILL.md) hands control back, this is how to drive and debug the app through
`TARGET_TAB_ID`.

- **Text > screenshot.** To inspect or click, use `find` or `read_page` (`filter=interactive`) —
  cheap, and it returns refs. A screenshot (~1.5k tokens, viewport only, no refs) is only for the
  *visual* (layout, CSS, render). The **first navigation to a route triggers an on-demand compile**
  (Vite/Turbopack/webpack); while it runs the renderer is busy and `screenshot`/CDP actions time
  out ("renderer busy"). Wait for the route to settle (or retry once); during the build, prefer
  text or `javascript_tool` reads.
- **Refs > coordinates.** Click via a `read_page`/`find` ref, never a hardcoded pixel coordinate —
  coordinates drift after any DOM change (a navigation, a sheet/modal opening, a list re-render, an
  on-demand compile) and the click lands on nothing, so you loop retrying. **Never click a confirm
  or destructive dialog button by coordinate** — `find` it for a stable ref first. After a click
  that mutates the DOM, re-read refs before the next action.
- **Predictable steps → `browser_batch`.** Chain known actions (`navigate`+`read_page`,
  `form_input` across several refs, click+type+press) in one call to cut round-trips. It does
  **not** pass output→input: if the next step needs a ref you only discover now, go the normal way.
  A batch skips the permission prompt only when **every** action in it is read-only — mixing
  `navigate` (state-changing) with reads keeps the token saving but forfeits the free pass.
- **Responsive/breakpoint testing.** Try it here first: call `resize_window`
  (`width`/`height`/`tabId`), then confirm with `javascript_tool` that `window.innerWidth`/
  `innerHeight` actually changed — a one-line check, cheap to run. It failed silently under a
  tiling WM in one measurement (asked for 390px, stayed at 2106 on Hyprland), so verify rather than
  trust the tool's own success return. Only when the resize doesn't stick, switch to `agent-browser`
  with a device profile instead of fighting this tab.
- **The server is watched; the client is on demand.** The Monitor notifies you on its own — but
  only from the **server log** (stdout). The **client** side (React, `fetch` 4xx/5xx, a browser
  exception) lives in the **browser console**, which the shell can't observe → **no automatic
  alert**. Run `read_console_messages` (`onlyErrors`) / `read_network_requests` on the tab **when**
  the screen looks broken or an action fails; don't wait for a spontaneous notification.
- **Scroll, then prove the scroll before the shot.** A screenshot right after a programmatic
  scroll (`scrollIntoView` via `javascript_tool`) can capture the page back at the top — the
  scroll and the capture race. Confirm the position first (read `window.scrollY`, or re-`find` the
  target) before shooting; a real run burned two scroll+screenshot cycles on this.
- **Storage/cookies.** `javascript_tool` reads `localStorage`/`sessionStorage` and non-HttpOnly
  cookies directly. A **HttpOnly** session cookie is invisible to JS — reading it would need a
  CDP/debug port, which abandons this setup, so it's out of reach here.
