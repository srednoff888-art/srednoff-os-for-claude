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

fp="$(printf '%s' "$raw" | jq -r '.tool_input.file_path // .tool_input.path // .tool_input.notebook_path // empty' 2>/dev/null || true)"

# Path rules (and the allow-list of committed-on-purpose names) live in hook-lib.sh so
# run-evals.sh can test them; see the comments there for why each name is allowed.
if is_secret_path "$fp"; then
  deny "Secret-like file path blocked by SREDNOFF OS hook. Ask the user for explicit approval; use a redacted approach." "secret_path"
elif is_secret_path_allowlisted "$fp"; then
  # The NAME is allowed (.env.example and friends), the CONTENT is not: a real key
  # committed into a template is still a leak, and on Read there is no tool_input to
  # scan, so check the file on disk.
  disk_hits=(); while IFS= read -r _line; do disk_hits+=("$_line"); done < <(scan_path_content_on_disk "$fp")
  if [ "${#disk_hits[@]}" -gt 0 ]; then
    disk_str="$(IFS=,; echo "${disk_hits[*]}")"
    deny "$fp is normally safe to read/edit, but it currently contains what looks like a real secret ($disk_str). Blocked by SREDNOFF OS hook - replace the value with a placeholder." "${disk_hits[@]}"
  fi
fi

# Content-based check: catches a secret being written into an otherwise-innocuous file
# (e.g. hardcoded into a .ts/.py source file), which the path check above cannot see.
#
# Covers every field a matcher in settings.example.json can actually deliver:
#   Write         -> content
#   Edit          -> new_string
#   MultiEdit     -> edits[].new_string   (an array - was not read at all before, so a
#                    secret written through MultiEdit passed straight through even though
#                    the matcher listed it: coverage was nominal, not real)
#   NotebookEdit  -> new_source           (same story)
# old_string is deliberately NOT scanned: it is the text being REMOVED, so it can never
# reach disk. Scanning it blocked the one thing you most want to allow - deleting a
# hardcoded key - and also blocked editing this repo's own secret fixtures.
content_field="$(printf '%s' "$raw" | jq -r '[.tool_input.content, .tool_input.new_string, .tool_input.new_source, (.tool_input.edits // [] | .[]? | .new_string)] | map(select(. != null)) | join("\n")' 2>/dev/null || true)"
# bash-3.2-compatible (macOS /bin/bash is 3.2.57, no `mapfile`): read lines into an array.
secret_hits=(); while IFS= read -r _line; do secret_hits+=("$_line"); done < <(find_secret_signals "$content_field")
if [ "${#secret_hits[@]}" -gt 0 ]; then
  hits_str="$(IFS=,; echo "${secret_hits[*]}")"
  deny "Content appears to contain a secret ($hits_str). Blocked by SREDNOFF OS hook." "${secret_hits[@]}"
fi
exit 0
