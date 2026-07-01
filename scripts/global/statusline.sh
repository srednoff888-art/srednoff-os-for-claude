#!/usr/bin/env bash
# SREDNOFF OS statusline (Linux/macOS port of statusline.ps1): shows ACTIVE (green) / OFF
# (red) for the current project. Wired via settings.json "statusLine". Reads JSON on
# stdin, prints ONE colored line. Requires: jq.
#
# Wiring (~/.claude/settings.json):
#   "statusLine": { "type": "command",
#     "command": "bash \"$HOME/.claude/templates/claude-md-os/scripts/global/statusline.sh\"" }
#
# Uses the same SREDNOFF_OS_ROOT env var as session-start-hook.sh (defaults to $HOME).
set -uo pipefail

raw="$(cat)"
cwd=""; model=""
if [ -n "$raw" ] && command -v jq >/dev/null 2>&1; then
  cwd="$(printf '%s' "$raw" | jq -r '.workspace.current_dir // .cwd // empty' 2>/dev/null || true)"
  model="$(printf '%s' "$raw" | jq -r '.model.display_name // empty' 2>/dev/null || true)"
fi
[ -z "$cwd" ] && cwd="$(pwd)"

esc=$'\033'
green="${esc}[92m"; red="${esc}[91m"; cyan="${esc}[96m"; dim="${esc}[2m"; bold="${esc}[1m"; reset="${esc}[0m"

name="$(basename "$cwd")"
root_guard="${SREDNOFF_OS_ROOT:-$HOME}"
in_workspace=0
case "$cwd" in "$root_guard"*) in_workspace=1 ;; esac
[ "${cwd%/}" = "${root_guard%/}" ] && in_workspace=0
has_os=0
[ -f "$cwd/.claude/rules/00-operating-system.md" ] && has_os=1

label="${bold}${cyan}SREDNOFF OS${reset}"

if [ "$in_workspace" -eq 0 ]; then
  echo "$label ${dim}(outside workspace)${reset}"
  exit 0
fi

if [ "$has_os" -eq 1 ]; then
  tags=""
  lock="$cwd/.claude/PROFILE.lock.md"
  if [ -f "$lock" ]; then
    tags="$(grep -m1 -E '^`[^`]+`$' "$lock" | sed 's/^`//; s/`$//')"
  fi
  line="$label ${green}* ACTIVE${reset} ${dim}|${reset} $name"
  [ -n "$model" ] && line="$line ${dim}|${reset} $model"
  [ -n "$tags" ] && line="$line ${dim}| ${tags}${reset}"
  echo "$line"
else
  echo "$label ${red}o OFF${reset} ${dim}|${reset} $name ${dim}(run init)${reset}"
fi
exit 0
