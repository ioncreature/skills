---
name: prompt-analysis
description: Analyze the user's Claude Code prompt history from ~/.claude/history.jsonl — time patterns, topics, interaction style, weekly evolution, plus a subjective reflection on working style.
---

# /prompt-analysis — History reflection

Reads `~/.claude/history.jsonl` and produces a structured report on how the user prompts: when, about what, in what tone, and how that has evolved. Output is delivered fully in the conversation — nothing is written to disk.

## Process

Run python3 scripts via the Bash tool to compute all stats. Stream the file line-by-line (don't load it whole — it can be tens of MB). Once stats are computed, present the report directly in the chat.

## Arguments (`$ARGUMENTS`)

Optional filters, any combination, space-separated:

- **Project name** — filter to prompts where the last path segment of `project` matches (e.g. `brain-game`).
- **Time range** — `last-week`, `last-month`, `last-3-months`, `last-year`, or an explicit `YYYY-MM-DD..YYYY-MM-DD` range.

Example: `/prompt-analysis brain-game last-month`

If no arguments, analyze the full history across all projects.

## Report sections

### 1. General stats
- Total prompts, date range, active days
- Projects breakdown (extract project name from the `project` field, last path segment)
- Note any active filters at the top

### 2. Time patterns
- **By hour** (0–23): histogram with `█` blocks
- **By day of week** (Mon–Sun): histogram
- **By month**: histogram
- **Daily activity**: every calendar day with count and bar
- **Most productive days**: top 10

### 3. Topics
Classify each prompt by keyword matching. Categories (extend if the data suggests more):

- New features: добавь, сделай, создай, реализуй, implement, add
- Bugs/errors: ошибка, баг, error, bug, fix, не работает, crash, проблема
- UI/design: экран, кнопк, стил, цвет, шрифт, screen, button, style, layout, дизайн
- Commits/git: коммит, commit, закоммить, пуш, push, git, merge
- Tests: тест, test, jest, spec
- Deploy/infra: деплой, deploy, docker, helm, stage, nginx, build, ci/cd
- API/backend: api, endpoint, backend, бэкенд, nest, typeorm, postgres
- i18n: i18n, локал, перевод, locale, translat
- Refactoring: рефакт, refactor, переименуй, перенес, extract, упрост
- Screenshots/review: screenshot, скриншот, погляди, посмотри, покажи

### 4. Weekly evolution
- Topic counts per ISO week (table)
- Project focus per week

### 5. Prompt style
- Length stats: avg, median, max
- Length distribution (buckets)
- Language detection: cyrillic-only, latin-only, mixed
- Most common 2-word starts (excluding slash commands)
- Slash command usage — list top commands and total share

### 6. Interaction patterns
- Approval phrases: отлично, хорошо, ок, да, perfect, great, класс, круто, мне нравится
- Rejection phrases: нет, не надо, не нужно, отмени, верни, убери, не так
- Continuation: продолжай, дальше, continue, давай еще
- Error/log pastes: в логах, появилась ошибка, error:, pasted text
- Approval : rejection ratio

### 7. Sessions
- Total sessions, avg/max prompts per session
- Session size distribution

### 8. Subjective reflection
After all the data is on the table, write a short, honest, respectful reflection on what the patterns suggest about the user's working style. Cover:

- Working rhythm and energy patterns (when they're sharp, when they grind)
- Collaboration mode (directive vs exploratory, trust level, how much they offload vs keep in their head)
- Emotional tone — what seems to motivate or frustrate them
- Anything specific from the prompt content that stood out

End the section with a one-line disclaimer:
> These are patterns in the data, not a diagnosis. Trust your own read.

## Output format

A single well-formatted markdown report in the chat. Tables, code blocks for bar charts, clear section headers. **Do not save to disk** — even if the user asks, mention that this skill is intentionally chat-only and they can copy the output manually.

## Implementation notes

- History file: `~/.claude/history.jsonl`, one JSON object per line.
- Each entry has: `display` (prompt text), `timestamp` (ms), `project` (path), `sessionId`.
- Stream the file (`for line in open(...)`); don't `read()` it all at once.
- Filter out `/rate-limit-options` prompts — they're automated noise.
- For topic/style sections, also exclude prompts starting with `/` (they're command invocations, not free-form intent). Slash commands are still counted separately in section 5.
- All bar charts use `█`, scaled to fit ~40 columns max.
- Render the report in the language that dominates the user's prompts (Cyrillic vs Latin majority).
- A session boundary: same `sessionId` = same session. If `sessionId` is missing, group by gaps > 30 minutes.

## Privacy note

`history.jsonl` can contain sensitive content — client names, secrets pasted by mistake, private details. Don't share the report verbatim outside the conversation without skimming it first.
