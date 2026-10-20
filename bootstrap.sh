#!/usr/bin/env bash
# Link skills into Claude Code and Codex; commands and home files into Claude Code;
# command rules into Codex.
# Safe to re-run: existing symlinks are refreshed; real files are left alone.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

link_dir() {
  local src_dir=$1 dst_dir=$2
  mkdir -p "$dst_dir"
  if [ ! -d "$src_dir" ]; then
    return 0
  fi
  for src in "$src_dir"/*; do
    [ -e "$src" ] || continue
    local name dst
    name="$(basename "$src")"
    dst="$dst_dir/$name"
    if [ -e "$dst" ] && [ ! -L "$dst" ]; then
      echo "skip: $dst exists and is not a symlink (remove it manually if you want to relink)"
      continue
    fi
    ln -sfn "$src" "$dst"
    echo "linked $dst → $src"
  done
}

link_dir "$ROOT/skills" "$HOME/.claude/skills"
link_dir "$ROOT/skills" "$HOME/.agents/skills"
link_dir "$ROOT/commands" "$HOME/.claude/commands"
# files that live at the root of ~/.claude (e.g. CLAUDE.md — user-scope memory)
link_dir "$ROOT/home" "$HOME/.claude"
# Codex loads every *.rules file in ~/.codex/rules; it writes its own approvals to default.rules
link_dir "$ROOT/codex/rules" "$HOME/.codex/rules"
