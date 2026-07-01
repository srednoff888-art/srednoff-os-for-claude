#!/usr/bin/env bash
# PreToolUse(Read|Edit|Write|MultiEdit) hook - block secret-like FILE PATHS and, separately,
# actual secret-shaped CONTENT being written. Linux/macOS port of protect-secrets.ps1.
# Requires: jq, grep -P (see hook-lib.sh).
# Wire via settings: bash .claude/hooks/protect-secrets.sh
set -uo pipefail
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=hook-lib.sh
. "$script_dir/hook-lib.sh"

raw="$(cat)"
[ -z "$raw" ] && exit 0
command -v jq >/dev/null 2>&1 || exit 0

deny() {
  local reason="$1"; shift
  write_hook_ledger "protect-secrets" "deny" "$raw" "$@"
  jq -nc --arg reason "$reason" \
    '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "deny", permissionDecisionReason: $reason}}'
  exit 0
}

fp="$(printf '%s' "$raw" | jq -r '.tool_input.file_path // .tool_input.path // empty' 2>/dev/null || true)"

secret_path_pattern='(^|[\\/])\.env(\.|$)|id_rsa|id_ed25519|\.pem$|\.key$|secrets?\.(json|ya?ml|toml)$|credentials(\.json)?$'
if [ -n "$fp" ] && printf '%s' "$fp" | grep -Pq "$secret_path_pattern" 2>/dev/null; then
  deny "Secret-like file path blocked by SREDNOFF OS hook. Ask the user for explicit approval; use a redacted approach." "secret_path"
fi

# Content-based check: catches a secret being written into an otherwise-innocuous file
# (e.g. hardcoded into a .ts/.py source file), which the path check above cannot see.
content_field="$(printf '%s' "$raw" | jq -r '[.tool_input.content, .tool_input.new_string, .tool_input.old_string] | map(select(. != null)) | join("\n")' 2>/dev/null || true)"
mapfile -t secret_hits < <(find_secret_signals "$content_field")
if [ "${#secret_hits[@]}" -gt 0 ]; then
  hits_str="$(IFS=,; echo "${secret_hits[*]}")"
  deny "Content appears to contain a secret ($hits_str). Blocked by SREDNOFF OS hook." "${secret_hits[@]}"
fi
exit 0
