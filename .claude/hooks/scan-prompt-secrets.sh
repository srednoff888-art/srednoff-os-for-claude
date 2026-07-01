#!/usr/bin/env bash
# UserPromptSubmit hook - block the prompt itself if it appears to contain a real secret
# (pasted API key, private key, JWT, etc). Linux/macOS port of scan-prompt-secrets.ps1.
# Contract: block via {"decision":"block","reason":...}. Requires: jq, grep -P.
# Wire via settings: bash .claude/hooks/scan-prompt-secrets.sh
set -uo pipefail
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=hook-lib.sh
. "$script_dir/hook-lib.sh"

raw="$(cat)"
[ -z "$raw" ] && exit 0
command -v jq >/dev/null 2>&1 || exit 0

text="$(printf '%s' "$raw" | jq -r '.prompt // empty' 2>/dev/null || true)"
[ -z "$text" ] && text="$raw"   # fallback: scan the raw payload if the prompt field name differs

mapfile -t hits < <(find_secret_signals "$text")
if [ "${#hits[@]}" -gt 0 ]; then
  hits_str="$(IFS=,; echo "${hits[*]}")"
  write_hook_ledger "scan-prompt-secrets" "block" "$raw" "${hits[@]}"
  reason="Your message appears to contain a secret ($hits_str). Blocked before submission by SREDNOFF OS. Remove the secret and resend, or store it in .env instead."
  jq -nc --arg reason "$reason" '{decision: "block", reason: $reason}'
  exit 0
fi
exit 0
