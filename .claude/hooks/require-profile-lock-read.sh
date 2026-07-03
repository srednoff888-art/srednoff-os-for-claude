#!/usr/bin/env bash
# PreToolUse(Edit|Write|MultiEdit) hook (Linux/macOS port of require-profile-lock-read.ps1).
# See that file's header for the full design rationale (fail-open by intent - this is a
# workflow-compliance nudge, not a security control).
set -uo pipefail

raw="$(cat)"
[ -z "$raw" ] && exit 0
command -v jq >/dev/null 2>&1 || exit 0

session_id="$(printf '%s' "$raw" | jq -r '.session_id // empty' 2>/dev/null || true)"
cwd="$(printf '%s' "$raw" | jq -r '.cwd // empty' 2>/dev/null || true)"
[ -z "$session_id" ] && exit 0
[ -z "$cwd" ] && exit 0

lock_path="$cwd/.claude/PROFILE.lock.md"
[ -f "$lock_path" ] || exit 0   # OS not deployed here - nothing to gate

marker_path="$HOME/.claude/logs/session-state/$session_id/profile-lock-read.marker"
[ -f "$marker_path" ] && exit 0   # already satisfied this session

reason="This project has SREDNOFF OS active (.claude/PROFILE.lock.md exists) and it has not been read yet this session. Read .claude/PROFILE.lock.md (or grep registry/CORE-300.md by tag - see 70-skills-registry.md) to see the tagged skill shortlist for this stack, then retry this edit. This is a one-time check per session."
jq -nc --arg reason "$reason" \
  '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "deny", permissionDecisionReason: $reason}}'
exit 0
