#!/usr/bin/env bash
# SREDNOFF OS mode router (Linux/macOS port of mode-router.ps1). Classifies a task brief
# into normal/deep/turbo and reports the matching budget + max shortlist size.
# TURBO fires ONLY on the literal word "turbo" (case-insensitive). Synonyms like
# "maximally", "don't skimp on tokens", "production", "security audit" trigger "deep",
# never "turbo" - Principle #1: quality first, but no silent uncontrolled scope growth.
#
# Usage:
#   ./mode-router.sh --brief "TURBO fix the checkout bug"
#   ./mode-router.sh --brief "do this maximally well, production launch" --json
set -uo pipefail
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$script_dir/routing-lib.sh"

brief=""
json=0
while [ $# -gt 0 ]; do
  case "$1" in
    --brief) brief="$2"; shift 2 ;;
    --json) json=1; shift ;;
    *) shift ;;
  esac
done

IFS='|' read -r mode budget max_cap turbo reason <<< "$(get_mode "$brief")"

if [ "$json" -eq 1 ]; then
  if command -v jq >/dev/null 2>&1; then
    jq -nc --arg name "SREDNOFF OS mode router" --arg mode "$mode" --arg budget "$budget" \
      --argjson max "$max_cap" --argjson turbo "$([ "$turbo" = "1" ] && echo true || echo false)" \
      --arg reason "$reason" \
      '{name: $name, mode: $mode, budget: $budget, max_capabilities: $max, turbo: $turbo, reason: $reason,
        safety: {destructive_confirmation_required: true, paid_confirmation_required: true, production_confirmation_required: true}}'
  else
    echo "jq not found - install jq for --json output" >&2
    exit 1
  fi
else
  echo "SREDNOFF OS mode: $mode | budget=$budget | max=$max_cap | reason=$reason"
fi
