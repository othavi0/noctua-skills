# Logging in

Read this from [`SKILL.md`](../SKILL.md) step 4.3, or whenever `page.url()` lands on a login route.

Pick the branch by whose credentials they are.

## A test user of this local app

Use this branch for a seeded or fixture user on `PORT.localhost`, when the user asks you to log in
or the repo documents a test login. The password goes from its source to the form through a file,
so it never appears in a tool call or its result.

1. Get the file path. `execute` on `tab: "dev-PORT"`:

   ```js
   return files.path("browse-up-PORT.secret");
   ```

2. Write the password to that path with one Bash call. Use the project's own source for it: a seed
   file, a fixture, or an env variable read through the project's runner.

   ```bash
   (umask 077; <command that prints the password> > '<path from step 1>')
   ```

   Redirect the output. Do not print the value, and do not paste it into `code`.
3. Log in with one `execute`. Take the selectors from a `snapshot()` of the form first.

   ```js
   const secret = (await files.read("browse-up-PORT.secret", "utf8")).trim();
   await files.write("browse-up-PORT.secret", "");
   await page.fill('input[name="username"]', "<user>");
   await page.fill('input[type="password"]', secret);
   await page.click('button[type="submit"]');
   await page.waitForURL((u) => !/login|auth|sign-in|entrar|acesso/.test(String(u)), { timeout: 15000 });
   return { url: page.url(), title: await page.title() };
   ```

   The script empties the file before it submits. Return the URL and nothing read from the file.

   `waitForURL` times out, or the next call says that another extension's popup covers the page →
   the browser's password manager is asking whether to save the password, and the browser blocks
   Browse until that popup closes. The login itself may have worked. Ask the user to dismiss the
   popup, then read `page.url()`. Do not submit again.
4. Confirm who is logged in. Read the user name the page shows and report it. A run once reported
   a login as `admin` while the page showed `dev`.

Log in as the user the request names. With none named, use the repo's documented default.

## Any other account

A real account, 2FA, a passkey, a captcha or an OAuth screen belongs to the user. Hand the tab
over and wait:

```js
const r = await handoff("Sign in, then click Continue.");
return { outcome: r.outcome, url: page.url() };
```

`outcome` is `continued`, `timeout`, `closed` or `cancelled`. Go on only after `continued`, and
read the page again: it has changed.

## The login does not hold

- The tab logs out by itself, or shows another port's user → the app runs on plain `localhost`.
  Restart on `http://PORT.localhost:PORT`, as [`SKILL.md`](../SKILL.md) says.
- Sign-in answers 403 `Invalid origin` → the auth origin variable still names another port. Apply
  the `warn pinned port` prefix from step 2.2 and Restart.
- OAuth returns to the production domain → copy the `?code=...` from that URL onto
  `http://PORT.localhost:PORT/<callback route>?code=...` in the same tab. The code works once and
  expires in minutes.
