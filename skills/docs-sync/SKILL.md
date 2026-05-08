---
name: docs-sync
description: Reconcile project documentation with the current code state. Inspects pending changes, locates affected CLAUDE.md / docs/specs/* / README files, and updates them to match reality. Run after a feature lands, before opening a PR.
---

# /docs-sync — Reconcile docs with code

Brings the project's documentation back in line with what the code actually does.

## Why

Docs drift every time a feature ships. By the time you remember to "обновить документацию", you've already forgotten which docs care about what changed. This skill closes the loop: code lands → docs catch up as the last step, automatically.

## Preconditions

- If the current branch has no pending changes (tracked or untracked), say so and stop. Don't open any docs.

## How to run

### Phase 1 — Understand what changed

1. Run `git diff` (and `git status -s` for untracked files). Read the actual changes, don't just summarize.
2. From the diff, extract:
   - **Modules touched** — path prefixes like `services/<name>`, `libs/<name>`, `web/<name>`, etc.
   - **Public surface changes** — exported functions, HTTP routes, env vars, CLI flags, event names, schema fields, config keys.
   - **Behavioral changes** — renamed/removed features, new defaults, changed validation, new error cases.
   - **Removed code** — features and APIs that no longer exist.

### Phase 2 — Locate affected docs

For each touched module, find candidate docs. Use `git ls-files` + grep, don't guess:

- Root `CLAUDE.md` and any nested `CLAUDE.md` inside touched directories.
- Spec files under `docs/specs/...` (check the actual layout — common patterns are `docs/specs/services/<name>.md`, `docs/specs/libs/<name>.md`, `docs/specs/web/<name>.md`).
- `README.md` inside the touched service/lib/package.
- Any doc that names a removed/renamed identifier — grep for the old name across `docs/`, `**/*.md`.
- API references, OpenAPI specs, schema definition files if the public surface changed.

If the repo's docs layout differs from common conventions, follow what's actually there.

### Phase 3 — Reconcile

For each candidate doc:

1. Read it.
2. Compare against the **current code**, not just the diff. Diff shows what moved; only current code shows what's true now.
3. Edit in place to match reality:
   - Fix outdated signatures, examples, response shapes.
   - Update sections describing changed behavior.
   - Remove docs for removed features.
   - Add a minimal stub for new features — only document what the code shows. Don't invent rationale or future plans.
4. Skip docs unrelated to the diff. Don't expand scope into proofreading, restyling, or rewriting neighbors that happen to be nearby.
5. Match the language already used in each doc — don't translate.

### Phase 4 — Report

Emit a single short report:

```
## /docs-sync result

### Code changes
- <one-line summary of what shipped in this branch>

### Docs updated
- <path>: <what was reconciled>
- <path>: <what was reconciled>

### Docs reviewed but already accurate
- <path>

### Drift you should know about
- <anything that couldn't be reconciled automatically — e.g. a spec that depends on a decision still in flight, or external docs outside this repo>
```

## Ground rules

- **Read the code, not just the diff.** Diff shows what changed; only the current code shows what's now true.
- **Don't invent.** If the code is ambiguous, write the doc to reflect what's there, not what you think it should be. Note ambiguity in the report.
- **Don't commit.** Wait for the user's explicit instruction. Pair with `/cp` (or run `/scp` instead) if you want to ship in one go.
- **Don't expand scope.** No restyling, no typo sweeps, no rewriting unrelated docs.
- **One language per doc.** Match each doc's existing language; don't translate.
- **Untouched ≠ correct.** Sometimes a doc is silent on changed behavior — that's still drift. Add the missing description rather than leaving the doc unchanged.
