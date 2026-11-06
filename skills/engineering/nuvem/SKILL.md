---
name: nuvem
description: >-
  Runs heavy work in a Claude Managed Agents session paid by the monthly API credit, then brings
  the patch back to review and deliver here. Use when invoking `/nuvem`, when asked to run a task
  in the cloud, on Managed Agents or "na nuvem", when a build, E2E run or measurement is too heavy
  for the local machine, or to check this month's API spend, credit and limits.
# allowed-tools is a Claude Code field, not part of the Agent Skills spec.
# Drop it before uploading this folder to claude.ai or the Skills API.
allowed-tools:
  - Bash(bash ${CLAUDE_SKILL_DIR}/scripts/nuvem.sh *)
---

# nuvem

The monthly API credit is the **ceiling**: no session opens unless this month's commitment plus the new session's cap fits under the lower of the credit and the Console spend limit, with a margin. The commitment counts what finished sessions spent, the full cap of live ones, and the external API use you declare. If the spend cannot be read, nothing opens.

`N="bash ${CLAUDE_SKILL_DIR}/scripts/nuvem.sh"`; `$N` alone lists the commands. Your values live in `~/.config/nuvem/` (`limits.conf` and `projects/`), and the state (agent, environment, sessions, uploads, outputs) lives in `~/.local/state/nuvem/`. `NUVEM_CONFIG` and `NUVEM_STATE` move them.

## First run

1. **Key.** A Claude API key in `~/.config/anthropic/api-key` (mode 600), or in `ANTHROPIC_API_KEY`. The user creates and saves it; you check only that the file exists and its size.
2. **Limits.** Copy the skill's `limits.conf` to `~/.config/nuvem/limits.conf` and fill `MONTHLY_CREDIT_CENTS` with the user's monthly credit. Read `CONSOLE_LIMIT_CENTS` from https://platform.claude.com/settings/spend-limits (in the user's browser, through Claude in Chrome when available). Both ship as `0`, so the ceiling refuses every session until they are set.
3. Done when `$N spend` prints a non-negative "free" line.

## Steps

1. **Spend.** Before each batch, open https://platform.claude.com/settings/spend-limits and read "Spend" and "Monthly spend limit". Update `CONSOLE_LIMIT_CENTS` if it changed. Set `EXTERNAL_SPEND_CENTS` to how much the Console's spend exceeds the total of `$N costs`, plus US$ 1, because the Console lags. Then run `$N spend`. Done when "free" covers the batch: sessions times the cap of each. Otherwise show the numbers to the user and stop. Raising the Console limit is the user's call.
2. **Settle.** Every product, rule or visual choice the task leaves open goes to the user before the cloud, as a question or a prototype. Done when the brief answers each point that changes behaviour.
3. **Project notes.** If `~/.config/nuvem/projects/<repo>.md` and `<repo>-local.md` are missing, write them now from the repo's docs, following `references/project-notes.md`. Done when both exist.
4. **Brief and bundle.** For each task `<name>`:
   - `git bundle create ~/.local/state/nuvem/<name>.bundle <refs>` with the refs the task needs; note the SHAs.
   - `~/.local/state/nuvem/<name>.md`: first `projects/<repo>.md`, then the task, with the user's goal, the issue text, the refs and SHAs, the branch, the patch base and name (`<name>.patch`), the done criteria and the checks with their expected output. `start` puts `references/brief-base.md` in front; it ends with "## The task".
   - Check in the code every path and premise the brief asserts, because the cloud works on top of them.

   Done when the brief depends on nothing that lives only in this conversation.
5. **Start.** `$N start <name> <brief> [cents] [support.tar.gz] [bundle]`; the bundle defaults to `~/.local/state/nuvem/<name>.bundle`, and `--dry-run` runs only the ceiling. One task per session. Tasks that touch the same doc or code region go in sequence, since in parallel they conflict at delivery.
6. **Wait.** `$N wait <name>` in the background, one per session. Done when it returns. A `budget_reached` stop with a partial report becomes a continuation session: the partial patch and report go in the support archive, and the brief says to apply them and go on.
7. **Fetch and archive.** `$N fetch <name>`, then `$N archive <name>`. Done when `archive` shows `"status":"terminated"` and the files sit in `~/.local/state/nuvem/out-<name>/`.
8. **Apply.** Treat the report as a hypothesis. In a fresh worktree of the current main, prepared as `projects/<repo>-local.md` says: `git am <patch>`, then `git commit --amend --reset-author --no-edit`. Run the cheap checks that note names, and open every screenshot yourself. Done when the patch applies and those checks pass here.
9. **Review and deliver.** A reviewer who did not write the patch gives a verdict on the current commit; any change after that needs a verdict on the interdiff. Delivery follows the repo's own process. Done when the change is delivered that way, or the failure has a written cause and its fix is in progress.
10. **Report.** Use the `$N costs` table: cost per session, month total, credit left, and what stays pending. Every failure here that the container could not see becomes a line in `projects/<repo>.md`.

## Pitfalls

- The Console spend limit blocks credit-paid use too. A session that hits it stops with `billing_error` and does not resume; open another.
- A session's cap is checked between requests, so the final cost lands slightly over it; the margin covers that.
- A regular API key cannot list non-Managed-Agents use, and the organization cost report needs an admin key; step 1 reads the Console for that reason.
- Archive sessions instead of deleting them: a deleted session drops out of the spend.
- Observed cost on Sonnet 5.5 in November 2026: a feature with a migration and E2E, US$ 4 to 6; a heavy measurement, US$ 3 to 4. Runtime is cents; tokens are the bill.
