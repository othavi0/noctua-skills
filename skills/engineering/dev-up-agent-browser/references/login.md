# Login recipes

Read this to save, check or remove the login recipe of a repo. `S` is the script command as
[`SKILL.md`](../SKILL.md) spells it.

A recipe is one project command that logs a test user in on the port's session without printing
the password. The recipe names the command and never holds a password: the project keeps that in
its own ignored file, which the agent never reads.

## Where it lives

One file per repo in `~/.config/dev-up-ab/logins/` (`$XDG_CONFIG_HOME/dev-up-ab/logins/` when that
is set, `$DEV_UP_AB_CONFIG/logins/` in tests), outside git. The key is the repo's `origin` URL as
`host/owner/repo`, so an https and an ssh clone, and every worktree of either, find the same file.
A repo with no `origin` uses `local` plus its git common dir. `S recipe` prints the key and the
file: `RECIPE key=K file=F` and the recipe, or `NO_RECIPE key=K file=F`.

The file holds `KEY=VALUE` lines:

- `cmd=`: the shell command. `{port}` stands for the port and is required; `{user}` stands for the
  user, quoted for the shell.
- `user=`: the default user, used when `login` gets none.

## Saving one

`S recipe set '<command>' [DEFAULT_USER]`, from any checkout of the repo, once the user agrees. For
crm-next:

```
S recipe set 'bash .claude/skills/verify-crm-next/scripts/verify.sh entrar {port} {user}' teste-admin
```

It answers `SAVED key=K file=F`. It refuses a command without `{port}` (exit 2) and one that
carries a password (`password=`, `senha=`, `--password`; exit 3). The file is readable only by the
user.

## Running it

`S login PORT [USER]` opens the session when it is closed, runs `cmd` with `bash -c` from the root
of the current checkout, and prints `LOGGED_IN user=U url=U` with the last 3 lines the command
printed, or `LOGIN_FAILED exit=N` with its last 5. A command that drives the browser goes through
`S ab PORT` (crm-next's `verify.sh` does), so it uses the session's browser and launches no other.

## Removing it

`S recipe rm`, only when the user asks. It prints `REMOVED key=K`.
