---
name: scp
description: Three-step runner — /simplify, docs sync, then /cp on the current branch's pending changes. Cleans the diff up (reuse, quality, efficiency), reconciles affected docs (CLAUDE.md, docs/*, README) with the code, then commits and pushes only what you touched in this conversation.
---

# /scp — Simplify + Docs + Commit-Push

A short alias that runs a cleanup pass, a docs reconciliation pass and a commit-push on the current branch's pending changes.

## Why

When you're ready to ship, you usually want, in one go:

1. A code cleanup pass (drop duplication, simplify, reuse existing utilities).
2. Docs brought back in line with what the code now does.
3. Commit and push only the files you touched in this conversation, with a meaningful English message.

Order matters: docs must describe the post-simplify code, and the commit must include both the cleanup and the doc edits.

## Preconditions

- If the current branch has no pending changes (tracked or untracked), say so and stop. Don't invoke either skill.

## How to run

### Step 1 — Simplify

Invoke the built-in `simplify` skill (via the Skill tool with `skill: "simplify"`).

- It reviews the changed files for reuse / quality / efficiency and edits them in place.
- Wait for it to finish.
- If `simplify` made edits, note them so they show up in the final summary.

### Step 2 — Docs sync

Reconcile the documentation with the code in the pending diff.

1. **Understand what changed.** Read `git diff` and `git status -s` (untracked files too). Extract the touched modules, public surface changes (exported functions, HTTP routes, env vars, CLI flags, event names, schema fields, config keys, alerts), behavioral changes and removed code.
2. **Locate affected docs** with `git ls-files` + grep, don't guess:
   - root `CLAUDE.md` and nested `CLAUDE.md` in touched directories;
   - `docs/**` (specs, runbooks, architecture) that describe the touched modules — follow the repo's actual layout and whatever `CLAUDE.md` says about where docs live;
   - `README.md` inside touched packages;
   - any doc naming a removed/renamed identifier (grep the old name).
3. **Reconcile.** Read each candidate and compare it against the **current code**, not just the diff. Fix outdated signatures, examples, behavior descriptions; remove docs for removed features; add a minimal description for new behavior the docs are silent on. Document only what the code shows — no invented rationale or plans.
4. **Stay in scope.** Skip unrelated docs; no restyling, typo sweeps or translation — match each doc's existing language.
5. If a doc can't be reconciled automatically (depends on an undecided question, lives outside this repo), don't guess — list it under "Drift" in the summary.

Doc files you edit here count as touched in this conversation, so `cp` picks them up.

### Step 3 — Commit and push

Invoke the `cp` skill (via the Skill tool with `skill: "cp"`).

- It commits and pushes only the files you touched in this conversation, with an English commit message.
- Wait for it to finish.

### Step 4 — Combined summary

Once all steps are done, emit a single short report:

```
## /scp result

### Simplify
- <what was fixed, file list>
- <or: nothing to change>

### Docs
- <path>: <what was reconciled>
- <or: already accurate>
- Drift: <what couldn't be reconciled, if any>

### Commit & push
- <commit hash + message, remote/branch>
- <or: nothing to commit>
```

## Ground rules

- **Run sequentially**, never in parallel — docs describe the post-simplify code, `cp` commits both.
- If `simplify` ran cleanly (with or without edits), proceed to Step 2.
- **Read the code, not just the diff** during docs sync: the diff shows what moved, only the current code shows what's true.
- If `simplify` crashed mid-edit or left the tree in a partial/unknown state, **stop**. Don't invoke `cp` — surface the failure and let the user decide. Auto-asking risks an autopilot "yes" that commits a half-rewritten tree.
