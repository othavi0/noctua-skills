# Interacting with and debugging the session

Read this before driving the app. Every browser call is `S ab PORT <agent-browser command>`.
`S ab PORT skills get core` prints agent-browser's own guide; read it once before long work.

- **Refs first.** `S ab PORT snapshot -i` lists the interactive elements with refs (`@e3`). Act
  through refs: `S ab PORT click @e3`, `S ab PORT fill @e5 "text"`. After a click that changes the
  DOM, take a fresh snapshot, since the old refs point at gone elements.
- **Screenshots for layout.** `S ab PORT screenshot /path/file.png`, then read the file. When the
  last argument is an image path (`.png`, `.jpg`, `.jpeg` or `.webp`, in any case), `ab` creates
  its folder; a selector such as `text=a/b.png` gets no folder. Text and
  refs come cheaper from `snapshot` and `get text`; keep the image for layout, CSS and render
  checks.
- **Navigation settles before you read it.** A click on an SPA link changes the URL a moment
  later: `S ab PORT wait --url '**/route'` (or `wait <selector>` of the new page), then
  `get url`.
- **Breakpoints.** `S ab PORT set viewport 390 844`, then confirm with
  `S ab PORT js 'window.innerWidth'`; `js -` reads a longer script from stdin. `js` runs
  agent-browser `eval` under another name, because a session isolated in a worktree refuses the
  word eval. The viewport is emulated, so it holds in headless and in a tiled window alike.
- **Scroll and layout without `js`.** `S ab PORT scroll down 500` and
  `S ab PORT scrollintoview @e3` scroll the page. `S ab PORT get box @e3` prints x, y, width and
  height, and `S ab PORT get styles @e3 | grep -E '^(color|font-size):'` reads computed styles. In
  938 sampled `js` calls, 29% only scrolled and 26% measured layout with `getBoundingClientRect`
  or `getComputedStyle`.
- **Client errors.** The watcher reads the server log only. React errors, failed fetches and page
  exceptions live in the browser: `S ab PORT errors`, `S ab PORT console`,
  `S ab PORT network requests --filter <pattern>` whenever the screen looks wrong or an action
  fails.
- **Compiling routes.** The first visit to a route starts an on-demand compile (Vite, Turbopack,
  webpack) and calls can time out. `S ab PORT wait <selector>` for the route, then retry once.
- **Several agents.** Each port has its own session, profile and browser. Two agents on one port
  share the session, so give each agent its own port.
