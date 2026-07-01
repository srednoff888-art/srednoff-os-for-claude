#!/usr/bin/env bash
# SREDNOFF OS catalog format validator (Linux/macOS port of validate-catalog-format.ps1).
# CORE-300.md is a flat markdown file parsed as a pseudo-database (get_core_catalog in
# routing-lib.sh) - a malformed numbered line silently VANISHES from parsing with no error.
# This catches that failure mode: (1) every "N. `name`" line has a group context and at
# least one [tag]; (2) numbers aren't reused; (3) no line has an empty backtick-name.
#
# Usage:
#   ./validate-catalog-format.sh
#   ./validate-catalog-format.sh --json
set -uo pipefail
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
core="$script_dir/CORE-300.md"
. "$script_dir/routing-lib.sh"

json=0
[ "${1:-}" = "--json" ] && json=1

# Re-scan raw lines to find "looks like a numbered entry but doesn't fully match" cases -
# these are exactly the ones get_core_catalog would silently drop.
suspicious_report="$(awk '
  {
    looks_numbered = ($0 ~ /^[ \t]*[0-9]+\.[ \t]/)
    fully_matches = ($0 ~ /^[ \t]*[0-9]+\.[ \t]+`[^`]+`/)
    if (looks_numbered && !fully_matches) {
      line = $0
      gsub(/^[ \t]+|[ \t]+$/, "", line)
      print NR "\t" line
    }
  }
' "$core")"
suspicious="$(count_nonempty_lines "$suspicious_report")"

catalog_tsv="$(get_core_catalog "$core")"
total_parsed="$(count_nonempty_lines "$catalog_tsv")"

no_tag_report="$(printf '%s\n' "$catalog_tsv" | awk -F'\t' '$4 == "" {print $1 "\t" $2}')"
no_tag_count="$(count_nonempty_lines "$no_tag_report")"

no_group_report="$(printf '%s\n' "$catalog_tsv" | awk -F'\t' '$3 == 0 {print $1 "\t" $2}')"
no_group_count="$(count_nonempty_lines "$no_group_report")"

dup_num_report="$(printf '%s\n' "$catalog_tsv" | awk -F'\t' '{c[$1]++} END{for (n in c) if (c[n]>1) print n}')"
dup_num_count="$(count_nonempty_lines "$dup_num_report")"

issues=()
if [ "$suspicious" -gt 0 ]; then
  while IFS=$'\t' read -r ln text; do
    [ -z "$ln" ] && continue
    issues+=("Line $ln looks numbered but has no valid backtick name (would silently drop from parsing): $text")
  done <<< "$suspicious_report"
fi
if [ "$no_tag_count" -gt 0 ]; then
  while IFS=$'\t' read -r num name; do
    [ -z "$num" ] && continue
    issues+=("Record #$num '$name' has zero tags - unreachable by domain/selector matching")
  done <<< "$no_tag_report"
fi
if [ "$no_group_count" -gt 0 ]; then
  while IFS=$'\t' read -r num name; do
    [ -z "$num" ] && continue
    issues+=("Record #$num '$name' has no group (0) - appeared before any GROUP/G1-G3 header")
  done <<< "$no_group_report"
fi
if [ "$dup_num_count" -gt 0 ]; then
  while read -r n; do
    [ -z "$n" ] && continue
    issues+=("Number #$n used more than once")
  done <<< "$dup_num_report"
fi

if [ "$json" -eq 1 ]; then
  if ! command -v jq >/dev/null 2>&1; then echo "jq not found - install jq for --json output" >&2; exit 1; fi
  issues_json="[]"
  [ "${#issues[@]}" -gt 0 ] && issues_json="$(printf '%s\n' "${issues[@]}" | jq -R . | jq -sc .)"
  jq -nc --arg name "SREDNOFF OS catalog validator" --argjson total "${total_parsed:-0}" \
    --argjson suspicious "${suspicious:-0}" --argjson no_tag "${no_tag_count:-0}" \
    --argjson no_group "${no_group_count:-0}" --argjson dup_nums "${dup_num_count:-0}" \
    --argjson issues "$issues_json" \
    '{name: $name, total_parsed: $total, suspicious_lines: $suspicious, no_tag_records: $no_tag,
      no_group_records: $no_group, duplicate_numbers: $dup_nums, issues: $issues}'
  [ "${#issues[@]}" -gt 0 ] && exit 1
  exit 0
fi

echo "SREDNOFF OS catalog validator: ${total_parsed:-0} records parsed"
if [ "${#issues[@]}" -eq 0 ]; then
  echo "  no issues found"
else
  printf '  ISSUE: %s\n' "${issues[@]}"
fi
[ "${#issues[@]}" -gt 0 ] && exit 1
exit 0
