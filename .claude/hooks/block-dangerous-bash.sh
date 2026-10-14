#!/usr/bin/env bash
# PreToolUse(Bash|PowerShell) hook - block dangerous shell commands AND secrets in the command text.
# Linux/macOS port of block-dangerous-bash.ps1. Requires: jq, grep -P (see hook-lib.sh).
# Wire via settings: bash .claude/hooks/block-dangerous-bash.sh
set -uo pipefail
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=hook-lib.sh
. "$script_dir/hook-lib.sh"

raw="$(cat)"
[ -z "$raw" ] && exit 0
command -v jq >/dev/null 2>&1 || exit 0
cmd="$(printf '%s' "$raw" | jq -r '.tool_input.command // empty' 2>/dev/null || true)"
[ -z "$cmd" ] && exit 0

deny() {
  local reason="$1"; shift
  write_hook_ledger "block-dangerous-bash" "deny" "$raw" "$@"
  jq -nc --arg reason "$reason" \
    '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "deny", permissionDecisionReason: $reason}}'
  exit 0
}

# Secret-in-command check (content-based, not just filename heuristics).
# bash-3.2-compatible (macOS /bin/bash is 3.2.57, no `mapfile`): read lines into an array.
secret_hits=(); while IFS= read -r _line; do secret_hits+=("$_line"); done < <(find_secret_signals "$cmd")
if [ "${#secret_hits[@]}" -gt 0 ]; then
  hits_str="$(IFS=,; echo "${secret_hits[*]}")"
  deny "Command appears to contain a secret ($hits_str). Blocked by SREDNOFF OS hook." "${secret_hits[@]}"
fi

# BUG FIXES (found via security-audit review, 2026-07-01), mirrored from block-dangerous-bash.ps1:
# (1) 'rm -rf /*' / 'rm -rf ./*' bypassed the old trailing whitespace/end-of-string check.
# (2) Long-form '--recursive --force' (either order) and reversed short flags '-fr' bypassed
#     the old '-rf'-only match.
# (3) 'git push -f' bypassed the old '--force'-only match.
# PowerShell-tool syntax (the PowerShell tool is a separate tool from Bash; with only a
# Bash matcher it skipped every hook): recursive Remove-Item / rd / del /s aimed at a
# drive root, the home directory, the current directory or a bare wildcard, and the
# disk-wiping cmdlets. A piped delete (Get-ChildItem -Recurse | Remove-Item) is NOT
# recognised.
danger_patterns=(
  '(^|[[:space:]])rm([[:space:]]+-[^[:space:]]+)*[[:space:]]+["'"'"']?(/|~|\$HOME|\$\{HOME\}|\.)["'"'"']?(\*|/\*)?["'"'"']?([[:space:]]|$)'
  '\bmkfs\b'
  '\bdd\b.*\bof=/dev/'
  ':\(\)\s*\{\s*:\|\:&\s*\};:'
  'chmod\s+-R\s+777\s+/'
  'git\s+push\s+.*(--force|-f)(\s|$)'
  'git\s+reset\s+--hard'
  '\bformat\s+[A-Za-z]:'
  '>\s*/dev/sd[a-z]'
  '(?i)\b(?:Remove-Item|ri|rm|rmdir|rd|del|erase)\b(?=[^;|&\n]*(?:-Recurse\b|\s/s\b))[^;|&\n]*?(?<=[\s\x22\x27=])(?:(?:~|\$HOME|\$\{HOME\}|\$env:(?:USERPROFILE|HOMEPATH|SystemDrive|SystemRoot|windir)|[A-Za-z]:|\.)(?:[\\/]\*?|\*)?|[\\/]\*?|\*)[\x22\x27]?(?=\s|$|[;|&)])'
  '(?i)\b(?:Format-Volume|Clear-Disk|Initialize-Disk|Remove-Partition)\b'
  '(?i)\bdiskpart\b'
)
for d in "${danger_patterns[@]}"; do
  if printf '%s' "$cmd" | srednoff_grep_pcre "$d"; then
    deny "Dangerous shell command blocked by SREDNOFF OS hook (pattern: $d)." "$d"
  fi
done
exit 0
