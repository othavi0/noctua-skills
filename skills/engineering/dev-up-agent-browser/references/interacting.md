# Interacting with and debugging the session

Read this before driving the app. Every browser call is `S ab PORT <agent-browser command>`.
`S ab PORT skills get core` prints agent-browser's own guide; read it once before long work.

- **Refs first.** `S ab PORT snapshot -i` lists the interactive elements with refs (`@e3`). Act
  through refs: `S ab PORT click @e3`, `S ab PORT fill @e5 "text"`. After a click that changes the
  DOM, take a fresh snapshot, since the old refs point at gone elements.
- **Screenshots for layout.** `S ab PORT screenshot /path/file.png`, then read the file. Text and
  refs come cheaper from `snapshot` and `get text`; keep the image for layout, CSS and render
  checks.
- **Breakpoints.** `S ab PORT set viewport 390 844`, then confirm with
  `S ab PORT eval 'window.innerWidth'`. The viewport is emulated, so it holds in headless and in a
  tiled window alike.
- **Client errors.** The watcher reads the server log only. React errors, failed fetches and page
  exceptions live in the browser: `S ab PORT errors`, `S ab PORT console`,
  `S ab PORT network requests --filter <pattern>` whenever the screen looks wrong or an action
  fails.
- **Compiling routes.** The first visit to a route starts an on-demand compile (Vite, Turbopack,
  webpack) and calls can time out. `S ab PORT wait <selector>` for the route, then retry once.
- **Several agents.** Each port has its own session, profile and browser. Two agents on one port
  share the session, so give each agent its own port.
