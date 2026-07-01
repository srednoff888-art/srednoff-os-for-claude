#!/usr/bin/env bash
set -euo pipefail

# Requires jq. On Windows install via: winget install jqlang.jq
payload="$(cat)"
command_text="$(printf '%s' "$payload" | jq -r '.tool_input.command // empty' 2>/dev/null || true)"

if printf '%s' "$command_text" | grep -Eiq '(^|[[:space:]])rm[[:space:]]+-rf[[:space:]]+(/|~|\$HOME|\.)|mkfs|dd[[:space:]].*of=/dev/|:(){:|:&};:|chmod[[:space:]]+-R[[:space:]]+777[[:space:]]+/' ; then
  jq -n '{
    "hookSpecificOutput": {
      "hookEventName": "PreToolUse",
      "permissionDecision": "deny",
      "permissionDecisionReason": "Dangerous shell command blocked by Claude MD OS hook."
    }
  }'
  exit 0
fi

exit 0
