#!/bin/sh
# Claude Code statusline: model, effort, context usage, plan limits (each if reported).
# Wired up via statusLine.command in home/settings.json; input is the statusline JSON on stdin.
# Context and limits turn yellow from WARN_PCT and red from CRIT_PCT; the 5h reset time shows from WARN_PCT.

WARN_PCT=70
CRIT_PCT=90

input=$(cat)

# One parse, fields joined by the ASCII unit separator: whitespace IFS would collapse empty fields.
SEP=$(printf '\037')

if ! command -v jq >/dev/null 2>&1; then
  printf 'statusline: jq not found'
  exit 0
fi

fields=$(printf '%s' "$input" | jq -r '
  def k: if . >= 1000000 then "\(. / 1000000 | floor)M" elif . >= 1000 then "\(. / 1000 | floor)k" else tostring end;
  (.context_window // {}) as $c
  | ($c.current_usage // {}) as $u
  | (($u.input_tokens // 0) + ($u.cache_creation_input_tokens // 0) + ($u.cache_read_input_tokens // 0)) as $used
  | ($c.context_window_size // 0) as $size
  | [
      (.model.display_name // "unknown" | sub(" *\\([^)]*context\\)"; "")),
      (.effort.level // ""),
      (if $used > 0 then "\($used | k)" else "" end),
      (if $used > 0 and $size > 0 then ($c.used_percentage // ($used * 100 / $size) | floor | tostring) else "" end),
      (.rate_limits.five_hour.used_percentage // "" | if . == "" then . else floor | tostring end),
      (.rate_limits.five_hour.resets_at // "" | tostring),
      (.rate_limits.seven_day.used_percentage // "" | if . == "" then . else floor | tostring end)
    ]
  | join("\u001f")')

IFS="$SEP" read -r model effort ctx ctx_pct h5_pct h5_reset d7_pct <<EOF
$fields
EOF

ESC=$(printf '\033')
# colorize <pct> <text>
colorize() {
  if [ "$1" -ge "$CRIT_PCT" ]; then
    printf '%s[31m%s%s[0m' "$ESC" "$2" "$ESC"
  elif [ "$1" -ge "$WARN_PCT" ]; then
    printf '%s[33m%s%s[0m' "$ESC" "$2" "$ESC"
  else
    printf '%s' "$2"
  fi
}

# hhmm <epoch> — BSD date first, GNU date as fallback
hhmm() {
  date -r "$1" +%H:%M 2>/dev/null || date -d "@$1" +%H:%M 2>/dev/null
}

out="$model"
[ -n "$effort" ] && out="$out · $effort"
[ -n "$ctx" ] && out="$out · $(colorize "$ctx_pct" "$ctx $ctx_pct%")"
if [ -n "$h5_pct" ]; then
  h5="5h $h5_pct%"
  if [ "$h5_pct" -ge "$WARN_PCT" ] && [ -n "$h5_reset" ]; then
    t=$(hhmm "$h5_reset") && [ -n "$t" ] && h5="${h5}→${t}"
  fi
  out="$out · $(colorize "$h5_pct" "$h5")"
fi
[ -n "$d7_pct" ] && out="$out · $(colorize "$d7_pct" "7d $d7_pct%")"

printf '%s' "$out"
