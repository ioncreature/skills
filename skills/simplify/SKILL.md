---
name: simplify
description: Review the changed code for reuse, simplification, efficiency, and altitude cleanups, then apply the fixes. Quality only — it does not hunt for bugs; use /code-review for that.
metadata:
  upstream-package: "@anthropic-ai/claude-code"
  upstream-version: "2.1.286"
  upstream-docs: "https://code.claude.com/docs/en/commands"
  upstream-parallel-sha256: "93afe5c60ecc4dbf96c0491abfa64b78ac58ce3035c6a11270e5beda3951b941"
  upstream-inline-sha256: "091d9fbd9286e5f2b6cb77aeaabf7f7f703db443524e071bfa87ed4e71ad7048"
---

# Simplify

Bundled Anthropic `/simplify` prompt extracted from `@anthropic-ai/claude-code`
2.1.286. The upstream text is preserved below; Anthropic's
[legal terms](https://code.claude.com/docs/en/legal-and-compliance) apply to it.

## Runtime compatibility

These rules adapt only tool names and scheduling in the upstream prompt below.

- Use the host's native subagent API for the upstream `Agent` tool: `Agent` in
  Claude Code, `collaboration.spawn_agent` in Codex.
- Run all four agent reviews. If fewer than four child-agent slots are available,
  launch concurrent waves that fit the available slots until all four reviews
  finish. A slot limit does not replace agent reviews with an inline pass.
- If the host provides no subagent API, follow the upstream
  [inline prompt](references/INLINE.md) instead of the parallel prompt below.

## Upstream parallel prompt

`/simplify → 4 cleanup agents in parallel → apply the fixes`

You are improving the quality of the changed code, not hunting for bugs. Review
it for reuse, simplification, efficiency, and altitude issues, then fix what you
find. Do not look for correctness bugs — that is what `/code-review` is for.

## Phase 0 — Gather the diff

Run `git diff @{upstream}...HEAD` (or `git diff main...HEAD` / `git diff HEAD~1`
if there's no upstream) to get the unified diff under review. If there are
uncommitted changes, or the range diff is empty, also run `git diff HEAD` and
include the working-tree changes in scope — the review often runs before the
commit. If a PR number, branch name, or file path was passed as an argument,
review that target instead. Treat this diff as the review scope.

## Phase 1 — Review (4 cleanup agents in parallel)

Launch **4 independent review agents** via the Agent tool, all in a
single message so they run concurrently. Pass each agent the diff and one of
the four angles below. Each returns its findings with `file`, `line`, a
one-line `summary`, and the concrete cost (what is duplicated, wasted, or
harder to maintain).

### Reuse

Flag new code that re-implements something the codebase
already has — Grep shared/utility modules and files adjacent to the change,
and name the existing helper to call instead.

### Simplification

Flag unnecessary complexity the diff adds: redundant or derivable state,
copy-paste with slight variation, deep nesting, dead code left behind. Name
the simpler form that does the same job.

### Efficiency

Flag wasted work the diff introduces: redundant computation or repeated I/O,
independent operations run sequentially, blocking work added to startup or
hot paths. Also flag long-lived objects built from closures or captured
environments — they keep the entire enclosing scope alive for the object's
lifetime (a memory leak when that scope holds large values); prefer a
class/struct that copies only the fields it needs. Name the cheaper
alternative.

### Altitude

Check that each change fixes the root cause at the right depth rather than
patching a symptom with a fragile bandaid. Special cases layered on shared
infrastructure are a sign the fix isn't deep enough — prefer the simpler, more
general change to the underlying mechanism over adding special cases, and name
that change.

## Phase 2 — Apply the fixes

Wait for all four agents to complete, dedup findings that point at the same
line or mechanism, and fix each remaining one directly. Skip any finding whose
fix would change intended behavior, require changes well outside the reviewed
diff, or that you judge to be a false positive — note the skip rather than
arguing with it. Finish with a brief summary of what was fixed and what was
skipped (or confirm the code was already clean).
