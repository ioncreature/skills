#!/bin/sh
# Claude Code statusline: model, effort (if reported), current dir, git branch.
# Wired up via statusLine.command in home/settings.json; input is the statusline JSON on stdin.

input=$(cat)

if command -v jq >/dev/null 2>&1; then
  model=$(printf '%s' "$input" | jq -r '.model.display_name // "unknown"')
  effort=$(printf '%s' "$input" | jq -r '.effort.level // empty')
  dir=$(printf '%s' "$input" | jq -r '.workspace.current_dir // .cwd // empty')
else
  model=$(printf '%s' "$input" | python3 -c '
import sys, json
d = json.load(sys.stdin)
print(d.get("model", {}).get("display_name", "unknown"))
')
  effort=$(printf '%s' "$input" | python3 -c '
import sys, json
d = json.load(sys.stdin)
print(d.get("effort", {}).get("level", ""))
')
  dir=$(printf '%s' "$input" | python3 -c '
import sys, json
d = json.load(sys.stdin)
w = d.get("workspace", {}) or {}
print(w.get("current_dir") or d.get("cwd") or "")
')
fi

dirname=$(basename "$dir" 2>/dev/null)

branch=""
if [ -n "$dir" ] && git --no-optional-locks -C "$dir" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  branch=$(git --no-optional-locks -C "$dir" branch --show-current 2>/dev/null)
fi

out="$model"
[ -n "$effort" ] && out="$out · $effort"
[ -n "$dirname" ] && out="$out · $dirname"
[ -n "$branch" ] && out="$out · $branch"

printf '%s' "$out"
