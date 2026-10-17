---
name: scp
description: Runner — /simplify, a bug review (a fresh-context subagent in Claude Code, `codex review` in Codex), a project-rules pass, docs sync, then /cp on the current branch's pending changes. Cleans the diff up (reuse, quality, efficiency), fixes confirmed bugs, aligns the changed code with the repo's own rules (AGENTS.md / CLAUDE.md), reconciles affected docs (CLAUDE.md, docs/*, README) with the code, then commits and pushes only what you touched in this conversation.
---

# /scp — Simplify + Review + Rules + Docs + Commit-Push

A short alias that runs a cleanup pass, a bug review, a project-rules pass, a docs reconciliation pass and a commit-push on the current branch's pending changes.

## Why

When you're ready to ship, you usually want, in one go:

1. A code cleanup pass (drop duplication, simplify, reuse existing utilities).
2. A bug review of the result — `simplify` doesn't look for bugs and can introduce them.
3. The changed code checked against the repo's own rules, which the generic passes don't know.
4. Docs brought back in line with what the code now does.
5. Commit and push only the files you touched in this conversation, with a meaningful English message.

Order matters: the review must see the post-simplify code, the rules pass also covers the review fixes, docs must describe the final code, and the commit must include all of it.

## Runtime compatibility

- **Claude Code:** invoke skills via the Skill tool.
- **Codex:** there is no Skill tool — open the `SKILL.md` of the skill the session lists under that name (user-level `~/.agents/skills/<name>/` or the repo's `.agents/skills/<name>/`) and follow it. Step 2 uses Codex's built-in reviewer instead of a subagent.

## Preconditions

- If the current branch has no pending changes (tracked or untracked), say so and stop. Don't invoke any skill.

## How to run

### Step 1 — Simplify

Invoke the `simplify` skill (`skill: "simplify"`).

- It reviews the changed files for reuse / quality / efficiency and edits them in place.
- Wait for it to finish.
- If `simplify` made edits, note them so they show up in the final summary.

### Step 2 — Bug review

Run a correctness review of the pending changes. It only reports; this step decides what to apply.

The reviewer must not see this conversation: an author's reasoning about the change biases the review. Triage below stays here, where the intent is known.

- **Claude Code:** spawn a fresh subagent (Agent tool, general-purpose — not a fork, which inherits this conversation) that does the review itself, synchronously. Don't use the `code-review` skill here: it may detach into a background job the subagent then has to wait on. Give the subagent the repo path and this task:
  1. Read `git diff`, `git diff --cached` and `git status -s`; read untracked files whole. For every hunk read the surrounding code, its callers and callees — not just the hunk.
  2. Look for correctness bugs only: wrong logic, edge cases (empty / null / undefined, off-by-one, boundaries), async and races, broken call contracts and changed signatures with stale callers, error handling that swallows or misroutes errors, SQL / migrations, data loss. Not style, naming, duplication or simplification — that's `simplify`'s job.
  3. Verify each candidate before reporting it: trace a concrete input or state through the actual code to the wrong output or crash. If the trace doesn't hold up, drop it.
  4. Return every surviving finding as a list (file, line, one-line summary, failure scenario), or "no findings". Don't edit any files.
- **Codex:** from the repo root run `codex review --uncommitted -c model_reasoning_effort='"medium"'` — the non-interactive form of Codex's `/review`, a separate Codex process with its own context. Give it up to ~10 minutes, and if the sandbox blocks it (network, writes to `~/.codex`), re-run it with escalated permissions. Findings come on stdout.

Triage each finding, checking in this order:

1. a false positive, or code this conversation didn't touch → skip it, note it in the summary;
2. the fix would change intended behavior or needs a product decision → don't fix it and **stop**: skip Steps 3–5, don't commit, and go to the summary (Step 6) with these findings under "Needs decision";
3. otherwise — a real bug in code changed in this conversation → fix it.

If the review can't run (tool error, usage limit, no network), continue without it and write `not run: <reason>` in the summary. Never report an unrun review as clean.

### Step 3 — Project rules

Check the changed code against the rules the repo itself sets.

1. **Collect the rules.** Read the root `AGENTS.md` / `CLAUDE.md` and nested ones in touched directories. Take only rules about code: comments, naming, file headers, logging, required helpers or CLIs, forbidden patterns.
2. **Check the diff** — including Step 1–2 edits — against those rules.
3. **Fix violations** in lines changed in this conversation. Don't fix pre-existing violations in untouched code and don't invent rules the files don't state. Where `simplify` or the review contradicts a repo rule, the repo rule wins.
4. A rule that can't be applied without a decision → don't commit: skip Steps 4–5 and list it under "Project rules → Needs decision" in the summary.

### Step 4 — Docs sync

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

### Step 5 — Commit and push

Invoke the `cp` skill (`skill: "cp"`).

- It commits and pushes only the files you touched in this conversation, with an English commit message.
- Wait for it to finish.

### Step 6 — Combined summary

Once all steps are done, emit a single short report:

```
## /scp result

### Simplify
- <what was fixed, file list>
- <or: nothing to change>

### Review (subagent | codex review)
- Fixed: <finding → fix, file>
- Skipped: <finding — why>
- Needs decision: <finding> (commit skipped)
- <or: no findings / not run: <reason>>

### Project rules
- <rule → what was fixed, file>
- Needs decision: <rule, where> (commit skipped)
- <or: no violations / no rules files>

### Docs
- <path>: <what was reconciled>
- <or: already accurate>
- Drift: <what couldn't be reconciled, if any>

### Commit & push
- <commit hash + message, remote/branch>
- <or: nothing to commit / skipped: <reason>>
```

## Ground rules

- **Run sequentially**, never in parallel — each step works on the previous step's output, `cp` commits all of it.
- If `simplify` ran cleanly (with or without edits), proceed to Step 2.
- **Read the code, not just the diff** during docs sync: the diff shows what moved, only the current code shows what's true.
- If `simplify` crashed mid-edit or left the tree in a partial/unknown state, **stop**. Don't invoke `cp` — surface the failure and let the user decide. Auto-asking risks an autopilot "yes" that commits a half-rewritten tree.
- A review finding or a project rule that needs a decision also stops the run before `cp`, for the same reason.
