#!/usr/bin/env bash
# PostToolUse(Read) hook (Linux/macOS port of mark-profile-lock-read.ps1). See that file's
# header comment for the full "why" - records real engagement with PROFILE.lock.md/CORE-300.md
# so require-profile-lock-read.sh can verify it instead of trusting a banner was noticed.
set -uo pipefail

raw="$(cat)"
[ -z "$raw" ] && exit 0
command -v jq >/dev/null 2>&1 || exit 0

session_id="$(printf '%s' "$raw" | jq -r '.session_id // empty' 2>/dev/null || true)"
file_path="$(printf '%s' "$raw" | jq -r '.tool_input.file_path // empty' 2>/dev/null || true)"
[ -z "$session_id" ] && exit 0
[ -z "$file_path" ] && exit 0

case "$file_path" in
  *PROFILE.lock.md|*CORE-300.md) ;;
  *) exit 0 ;;
esac

state_dir="$HOME/.claude/logs/session-state/$session_id"
mkdir -p "$state_dir" 2>/dev/null || exit 0
: > "$state_dir/profile-lock-read.marker" 2>/dev/null || true
exit 0
