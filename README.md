# Claude customizations

Versioned user-scope skills and slash commands for [Claude Code](https://claude.com/claude-code),
linked into `~/.claude/` so they're available in every project.

## Layout

```
skills/<name>/SKILL.md   # user-scope skill (invocable via the Skill tool / slash command)
commands/<name>.md       # user-scope slash command
bootstrap.sh             # creates symlinks ~/.claude/skills/<name> and ~/.claude/commands/<name>.md
```

## Install on a new machine

```sh
git clone git@github.com:ioncreature/skills.git ~/skills
~/skills/bootstrap.sh
```

Re-running `bootstrap.sh` is safe — it refreshes existing symlinks and skips real files.

## What's here

| Path | Invoke | Purpose |
| --- | --- | --- |
| `skills/ss` | `/ss` | Simplify + security-review two-step runner. Cleans the working tree with `simplify`, then scans the final diff with `security-review`. Use before a PR. |
| `commands/cp.md` | `/cp` | Commit and push only the changes you made in the current session, with an English commit message. |

## Add a new skill / command

1. Create `skills/<name>/SKILL.md` or `commands/<name>.md` in this repo.
2. Commit and push.
3. Run `~/skills/bootstrap.sh` on every machine (or just once, then `git pull` everywhere).
