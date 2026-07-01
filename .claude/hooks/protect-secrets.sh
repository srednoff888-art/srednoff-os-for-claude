#!/usr/bin/env bash
set -euo pipefail

# Requires jq. On Windows install via: winget install jqlang.jq
payload="$(cat)"
file_path="$(printf '%s' "$payload" | jq -r '.tool_input.file_path // .tool_input.path // empty' 2>/dev/null || true)"

if printf '%s' "$file_path" | grep -Eiq '(^|/)\.env(\.|$)|id_rsa|id_ed25519|\.pem$|\.key$|secrets?\.(json|yaml|yml|toml)$' ; then
  jq -n '{
    "hookSpecificOutput": {
      "hookEventName": "PreToolUse",
      "permissionDecision": "deny",
      "permissionDecisionReason": "Secret-like file access blocked. Ask the user for explicit approval and use a redacted approach."
    }
  }'
  exit 0
fi

exit 0
