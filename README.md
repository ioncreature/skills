# Claude Code and Codex customizations

Versioned user-scope skills and slash commands for [Claude Code](https://claude.com/claude-code),
with skill folders also linked into `~/.agents/skills` for Codex. The `cp` skill
works in both agents; commands and `home/` files are Claude-specific, `codex/` files are Codex-specific.

## Layout

```
skills/<name>/SKILL.md   # user-scope skill (Claude: /<name>; Codex: $<name>)
commands/<name>.md       # user-scope slash command
home/<file>              # files linked into the root of ~/.claude (e.g. home/CLAUDE.md → ~/.claude/CLAUDE.md)
codex/rules/<file>.rules # Codex command rules linked into ~/.codex/rules/
bootstrap.sh             # links skills into ~/.claude/skills and ~/.agents/skills; commands and home into ~/.claude/; codex/rules into ~/.codex/rules/
```

## Install on a new machine

```sh
git clone git@github.com:ioncreature/skills.git ~/skills
~/skills/bootstrap.sh
```

Re-running `bootstrap.sh` is safe — it refreshes existing symlinks and skips real files.

In Codex, invoke the commit-and-push skill with `$cp` (or select it from `/skills`
in the CLI/IDE). Codex follows symlinked skill folders and detects newly installed
skills automatically; restart Codex if `cp` does not appear. See the
[official OpenAI documentation](https://learn.chatgpt.com/docs/build-skills).

> **Note:** `bootstrap.sh` never overwrites a real file — it only (re)links. If a machine already
> has a real `~/.claude/CLAUDE.md`, merge anything worth keeping into `home/CLAUDE.md` first, then
> remove the local file and re-run `bootstrap.sh` to replace it with the symlink.
> `/auto-mode-setup` can replace the `~/.claude/settings.json` symlink with a real file; check
> `ls -la ~/.claude/settings.json` after running it and merge its `autoMode` back into `home/settings.json`.
>
> `~/.codex/config.toml` is not versioned: the Codex app rewrites it (UI state, trusted folders,
> plugin versions) and it may hold MCP credentials.

## What's here

| Path | Invoke | Purpose |
| --- | --- | --- |
| `skills/ss` | `/ss` | Simplify + security-review two-step runner. Cleans the working tree with `simplify`, then scans the final diff with `security-review`. Use before a PR. |
| `skills/scp` | `/scp` | Simplify + review + rules + docs sync + commit-push runner. Cleans the working tree with `simplify`, runs a medium-effort bug review (`/code-review` in Claude Code, `codex review` in Codex), checks the changed code against the repo's `AGENTS.md` / `CLAUDE.md` rules, reconciles affected `CLAUDE.md` / `docs/**` / `README.md` with the code, then commits and pushes only what you touched this session via `cp`. |
| `skills/prompt-analysis` | `/prompt-analysis` | Analyze `~/.claude/history.jsonl` — time patterns, topics, interaction style, weekly evolution, plus a subjective reflection. Chat-only output. Optional args: project name and/or time range (`last-week`, `last-month`, etc.). |
| `skills/cp` | Claude: `/cp`; Codex: `$cp` | Commit and push only your changes from the current conversation, with an English commit message. Excludes pre-existing and unrelated staged changes. |
| `commands/cp.md` | `/cp` | Original Claude Code command, retained for compatibility. |
| `home/CLAUDE.md` | — | User-scope memory: personal rules applied in every project, linked to `~/.claude/CLAUDE.md`. Versioned here so the same rules follow you across machines. |
| `home/settings.json` | — | User-scope settings linked to `~/.claude/settings.json`: permission allowlist, language, effort level, status line, voice, enabled plugins. Curated to safe, generic, cross-project entries (no one-off paths/PIDs). |
| `home/statusline.sh` | — | Status line script linked to `~/.claude/statusline.sh`, wired via `statusLine` in `home/settings.json`. Shows `model · effort · context used/size % · 5h/7d plan limits` (each segment only when reported). Context and limits turn yellow at 70% and red at 90%; from 70% the 5h limit also shows its reset time. Requires `jq` (ships with macOS 15+). |
| `codex/rules/user.rules` | — | Codex command rules (`prefix_rule`) linked to `~/.codex/rules/user.rules`: they decide what runs outside the sandbox (`allow` / `prompt` / `forbidden`, strictest wins). Forbids force push; allows commands that otherwise needed escalation. Codex keeps writing its own TUI approvals to `default.rules` — move the lasting ones here. Check with `codex execpolicy check --pretty --rules <file> -- <command>`. |

## Add a new skill / command

1. Create `skills/<name>/SKILL.md` or `commands/<name>.md` in this repo.
2. Commit and push.
3. Run `~/skills/bootstrap.sh` on every machine (or just once, then `git pull` everywhere).
