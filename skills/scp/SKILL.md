---
name: scp
description: Two-step runner — /simplify followed by /cp on the current branch's pending changes. Cleans the diff up first (reuse, quality, efficiency), then commits and pushes only what you touched in this conversation.
---

# /scp — Simplify + Commit-Push

A short alias that runs two skills back-to-back on the current branch's pending changes.

## Why

When you're ready to ship, you usually want, in one go:

1. A code cleanup pass (drop duplication, simplify, reuse existing utilities).
2. Commit and push only the files you touched in this conversation, with a meaningful English message.

Order matters: the commit must include `simplify`'s edits, so simplify runs first.

## Preconditions

- If the current branch has no pending changes (tracked or untracked), say so and stop. Don't invoke either skill.

## How to run

### Step 1 — Simplify

Invoke the built-in `simplify` skill (via the Skill tool with `skill: "simplify"`).

- It reviews the changed files for reuse / quality / efficiency and edits them in place.
- Wait for it to finish.
- If `simplify` made edits, note them so they show up in the final summary.

### Step 2 — Commit and push

Invoke the `cp` skill (via the Skill tool with `skill: "cp"`).

- It commits and pushes only the files you touched in this conversation, with an English commit message.
- Wait for it to finish.

### Step 3 — Combined summary

Once both steps are done, emit a single short report:

```
## /scp result

### Simplify
- <what was fixed, file list>
- <or: nothing to change>

### Commit & push
- <commit hash + message, remote/branch>
- <or: nothing to commit>
```

## Ground rules

- **Run sequentially**, never in parallel — `cp` must commit the post-simplify code.
- If `simplify` ran cleanly (with or without edits), proceed to Step 2.
- If `simplify` crashed mid-edit or left the tree in a partial/unknown state, **stop**. Don't invoke `cp` — surface the failure and let the user decide. Auto-asking risks an autopilot "yes" that commits a half-rewritten tree.
