# Claude customizations

Versioned user-scope skills and slash commands for [Claude Code](https://claude.com/claude-code),
linked into `~/.claude/` so they're available in every project.

## Layout

```
skills/<name>/SKILL.md   # user-scope skill (invocable via the Skill tool / slash command)
commands/<name>.md       # user-scope slash command
home/<file>              # files linked into the root of ~/.claude (e.g. home/CLAUDE.md → ~/.claude/CLAUDE.md)
bootstrap.sh             # creates the symlinks under ~/.claude/{skills,commands} and ~/.claude/
```

## Install on a new machine

```sh
git clone git@github.com:ioncreature/skills.git ~/skills
~/skills/bootstrap.sh
```

Re-running `bootstrap.sh` is safe — it refreshes existing symlinks and skips real files.

> **Note:** `bootstrap.sh` never overwrites a real file — it only (re)links. If a machine already
> has a real `~/.claude/CLAUDE.md`, merge anything worth keeping into `home/CLAUDE.md` first, then
> remove the local file and re-run `bootstrap.sh` to replace it with the symlink.

## What's here

| Path | Invoke | Purpose |
| --- | --- | --- |
| `skills/ss` | `/ss` | Simplify + security-review two-step runner. Cleans the working tree with `simplify`, then scans the final diff with `security-review`. Use before a PR. |
| `skills/scp` | `/scp` | Simplify + docs sync + commit-push runner. Cleans the working tree with `simplify`, reconciles affected `CLAUDE.md` / `docs/**` / `README.md` with the code, then commits and pushes only what you touched this session via `cp`. |
| `skills/prompt-analysis` | `/prompt-analysis` | Analyze `~/.claude/history.jsonl` — time patterns, topics, interaction style, weekly evolution, plus a subjective reflection. Chat-only output. Optional args: project name and/or time range (`last-week`, `last-month`, etc.). |
| `commands/cp.md` | `/cp` | Commit and push only the changes you made in the current session, with an English commit message. |
| `home/CLAUDE.md` | — | User-scope memory: personal rules applied in every project, linked to `~/.claude/CLAUDE.md`. Versioned here so the same rules follow you across machines. |
| `home/settings.json` | — | User-scope settings linked to `~/.claude/settings.json`: permission allowlist, language, effort level, status line, voice, enabled plugins. Curated to safe, generic, cross-project entries (no one-off paths/PIDs). |
| `home/statusline.sh` | — | Status line script linked to `~/.claude/statusline.sh`, wired via `statusLine` in `home/settings.json`. Shows `model · effort · dir · git branch` (effort only when the model reports it). Uses `jq`, falls back to `python3`. |

## Add a new skill / command

1. Create `skills/<name>/SKILL.md` or `commands/<name>.md` in this repo.
2. Commit and push.
3. Run `~/skills/bootstrap.sh` on every machine (or just once, then `git pull` everywhere).
