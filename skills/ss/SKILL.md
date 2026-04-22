---
name: ss
description: Two-step runner — /simplify followed by /security-review on the current branch's pending changes. Cleans the diff up first (reuse, quality, efficiency), then scans the final code for security issues. Use before a PR for a double-check.
---

# /ss — Simplify + Security-review

A short alias that runs two built-in skills back-to-back on the current branch's pending changes.

## Why

Before opening a PR you usually want, in one go:

1. A code cleanup pass (drop duplication, simplify, reuse existing utilities).
2. A check that nothing insecure survived into the final diff.

Order matters: `security-review` must see the **final** state of the code, not something that
`simplify` will rewrite afterwards.

## How to run

### Step 1 — Simplify

Invoke the built-in `simplify` skill (via the Skill tool with `skill: "simplify"`).

- It reviews the changed files for reuse / quality / efficiency and edits them in place.
- Wait for it to finish.
- If `simplify` made edits, capture them in the final summary (file list, what changed).

### Step 2 — Security-review

Invoke the built-in `security-review` skill (via the Skill tool with `skill: "security-review"`).

- It scans the **updated** diff (including simplify's edits) for security vulnerabilities.
- Wait for it to finish.

### Step 3 — Combined summary

Once both steps are done, emit a single short report:

```
## /ss result

### Simplify
- <what was fixed, file list>
- <or: nothing to change>

### Security-review
- <findings with severity>
- <or: no issues found>

### Verdict
<one line: ready for PR / fixes needed / blocking issues>
```

## Ground rules

- **Do not commit** — never run `git commit`. Wait for the user's explicit instruction.
- **Run sequentially**, never in parallel — security-review must see the post-simplify code.
- If `simplify` crashes or refuses to run, still run `security-review` and note the simplify
  failure in the summary.
- If the current branch has no pending changes, say so and don't run anything.
