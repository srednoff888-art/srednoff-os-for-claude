#!/usr/bin/env bash
# SREDNOFF OS registry audit (Linux/macOS port of audit-registry.ps1). Catches duplicate
# skill names (confuses the selector/canon) and counts external (non-INST/ANTH) records
# that are due for a staleness re-check. Does NOT hit the network - cheap, always-safe
# first line of defense.
#
# Usage:
#   ./audit-registry.sh
#   ./audit-registry.sh --json
set -uo pipefail
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
core="$script_dir/CORE-300.md"
if [ ! -f "$core" ]; then echo "CORE-300.md not found: $core" >&2; exit 1; fi
. "$script_dir/routing-lib.sh"

json=0
[ "${1:-}" = "--json" ] && json=1

catalog_tsv="$(get_core_catalog "$core")"
total_records="$(printf '%s\n' "$catalog_tsv" | grep -c . || true)"

# Duplicate names (case-insensitive).
dup_report="$(printf '%s\n' "$catalog_tsv" | awk -F'\t' '{ name=tolower($2); nums[name] = nums[name] (nums[name]=="" ? "" : ",") $1; cnt[name]++ } END { for (n in cnt) if (cnt[n] > 1) print n "\t" cnt[n] "\t" nums[n] }')"
duplicate_count="$(printf '%s\n' "$dup_report" | grep -c . || true)"
[ -z "$dup_report" ] && duplicate_count=0

# Portable word-boundary substitute (POSIX ERE has no \b/\< \>): require a non-letter or
# string edge on both sides so e.g. "EXT" doesn't match inside an unrelated longer word.
external_records="$(printf '%s\n' "$catalog_tsv" | awk -F'\t' '$5 ~ /GH:|WSH|VOLT|FTB|(^|[^A-Za-z])EXT([^A-Za-z]|$)/' | grep -c . || true)"
installed_records="$(printf '%s\n' "$catalog_tsv" | awk -F'\t' '$5 ~ /(^|[^A-Za-z])(INST|ANTH)([^A-Za-z]|$)|ANTH-OFF/' | grep -c . || true)"

if [ "$json" -eq 1 ]; then
  if ! command -v jq >/dev/null 2>&1; then echo "jq not found - install jq for --json output" >&2; exit 1; fi
  dups_json="[]"
  if [ -n "$dup_report" ]; then
    dups_json="$(printf '%s\n' "$dup_report" | while IFS=$'\t' read -r name count nums; do
      jq -nc --arg name "$name" --argjson count "$count" --arg nums "$nums" \
        '{name: $name, count: $count, nums: ($nums | split(","))}'
    done | jq -sc '.')"
  fi
  jq -nc --arg name "SREDNOFF OS registry audit" --argjson total "${total_records:-0}" \
    --argjson dups "$dups_json" --argjson dup_count "${duplicate_count:-0}" \
    --argjson ext "${external_records:-0}" --argjson inst "${installed_records:-0}" \
    '{name: $name, total_records: $total, duplicate_names: $dups, duplicate_count: $dup_count,
      external_records: $ext, installed_records: $inst,
      external_recheck_due: "quarterly (see CHANGELOG.md policy) - next due ~2026-09-28"}'
  [ "${duplicate_count:-0}" -gt 0 ] && exit 1
  exit 0
fi

echo "SREDNOFF OS registry audit: ${total_records:-0} records (${installed_records:-0} installed, ${external_records:-0} external)"
if [ "${duplicate_count:-0}" -eq 0 ]; then
  echo "  duplicates: none"
else
  echo "  duplicates: ${duplicate_count}"
  printf '%s\n' "$dup_report" | while IFS=$'\t' read -r name _count nums; do
    echo "    '$name' appears at #${nums//,/, #}"
  done
fi
echo "  external staleness recheck: quarterly (see CHANGELOG.md policy) - next due ~2026-09-28"
[ "${duplicate_count:-0}" -gt 0 ] && exit 1
exit 0
