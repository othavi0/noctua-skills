# Browser cache — why deviceId and name both matter

Read this from [`SKILL.md`](../SKILL.md) step 4.1 when picking between two or more connected
browsers.

## Why both fields are checked

Which field stays stable across sessions depends on the extension/setup: in some, the `deviceId`
is regenerated each session, so `name` is the stable key; in others (observed in practice), the
`deviceId` stays constant for weeks while the `name` churns — a named device silently reverts to a
generic `"Browser 1/2/3"`, and a name set via `switch_browser` may never appear back in
`list_connected_browsers`. Checking either field against the cache survives both cases.

## Legacy cache format

A cache file with a single bare line and no `=` predates the two-field format. Treat it as `name=`
and match by name only; rewrite it to the two-line form on the next miss.

## `switch_browser` doesn't return a deviceId

Optionally run `switch_browser` on a miss so the user can name the device, but don't rely on that
name sticking — the deviceId is the durable key you cache. `switch_browser` itself doesn't return
one: after `select_browser`, call `list_connected_browsers` once more and copy the exact `deviceId`
from there.

## A cache hit still isn't a guarantee

`list_connected_browsers`'s own output ends with a hard "you MUST call AskUserQuestion … do not
pick one yourself" instruction — that's the *no-cache* case and doesn't apply on a hit. Separately,
the extension keeps its own approval modes (Manual/Auto/Skip); a native permission prompt can still
appear on a hit, and that's not a cache failure either.
