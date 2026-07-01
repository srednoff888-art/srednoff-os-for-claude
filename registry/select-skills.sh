#!/usr/bin/env bash
# SREDNOFF OS quality/cost selector (Linux/macOS port of select-skills.ps1). Picks a
# shortlist from CORE-300.md by relevance to a task brief and by budget-shaped group
# quotas, WITHOUT loading the whole catalog into context.
# Principle #1 still governs: quality first, economy only at equal quality - this selector
# only fills a group quota with records that are actually tag-relevant; it never pads the
# shortlist with irrelevant filler just to hit a number.
#
# Usage:
#   ./select-skills.sh --brief "add Stripe checkout to the Next.js app" --budget balanced --max 16
#   ./select-skills.sh --brief "TURBO full security audit before launch" --json
set -uo pipefail
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$script_dir/routing-lib.sh"

core="$script_dir/CORE-300.md"
if [ ! -f "$core" ]; then echo "CORE-300.md not found: $core" >&2; exit 1; fi

brief=""; budget=""; max=0; tags_arg=""; json=0; nolog=0
while [ $# -gt 0 ]; do
  case "$1" in
    --brief) brief="$2"; shift 2 ;;
    --budget) budget="$2"; shift 2 ;;
    --max) max="$2"; shift 2 ;;
    --tags) tags_arg="$2"; shift 2 ;;
    --json) json=1; shift ;;
    --no-log) nolog=1; shift ;;
    *) shift ;;
  esac
done

IFS='|' read -r mode mode_budget mode_max _turbo _reason <<< "$(get_mode "$brief")"
[ -z "$budget" ] && budget="$mode_budget"
[ "$max" -le 0 ] && max="$mode_max"

if [ -n "$tags_arg" ]; then
  domain_csv="$(printf '%s' "$tags_arg" | tr ',' '\n' | sed 's/^[[:space:]]*//; s/[[:space:]]*$//' | paste -sd, -)"
else
  domain_csv="$(get_domain_tags "$brief" | paste -sd, -)"
fi

q1="$(budget_quota "$budget" 1)"
q2="$(budget_quota "$budget" 2)"
q3="$(budget_quota "$budget" 3)"

catalog_tsv="$(get_core_catalog "$core")"

# Relevance = count of tags overlapping the requested domain. [meta] does NOT count toward
# relevance (fallback only, so universal skills stay reachable) but a specific match must
# always outrank a generic [meta] entry - sorted by (relevance desc, num asc).
selection="$(printf '%s\n' "$catalog_tsv" | awk -F'\t' -v domains="$domain_csv" -v max="$max" -v q1="$q1" -v q2="$q2" -v q3="$q3" '
  BEGIN {
    nd = split(domains, dArr, ",")
    for (i = 1; i <= nd; i++) domainSet[dArr[i]] = 1
  }
  {
    num = $1; name = $2; group = $3; tagsField = $4
    m = split(tagsField, tArr, ",")
    specific = 0; isMeta = 0
    for (i = 1; i <= m; i++) {
      t = tArr[i]
      if (t == "meta") isMeta = 1
      else if (t in domainSet) specific++
    }
    if (specific > 0 || isMeta) {
      cnt[group]++
      idx = cnt[group]
      rel[group, idx] = specific
      numv[group, idx] = num + 0
      namev[group, idx] = name
      tagsv[group, idx] = tagsField
      matchedTotal++
    }
  }
  END {
    print "MATCHED_TOTAL\t" matchedTotal
    for (g = 1; g <= 3; g++) {
      quota = (g == 1 ? q1 : (g == 2 ? q2 : q3))
      groupQuota = int(max * quota)
      if (max * quota > groupQuota) groupQuota++   # ceil
      if (groupQuota <= 0) continue
      c = cnt[g]
      for (i = 1; i <= c; i++) order[i] = i
      for (i = 2; i <= c; i++) {
        key = order[i]; j = i - 1
        while (j >= 1 && (rel[g, order[j]] < rel[g, key] || (rel[g, order[j]] == rel[g, key] && numv[g, order[j]] > numv[g, key]))) {
          order[j + 1] = order[j]; j--
        }
        order[j + 1] = key
      }
      picked = 0
      for (i = 1; i <= c && picked < groupQuota; i++) {
        idx = order[i]
        print "PICK\t" numv[g, idx] "\t" namev[g, idx] "\t" g "\t" tagsv[g, idx]
        picked++
      }
    }
  }
')"

matched_total="$(printf '%s\n' "$selection" | awk -F'\t' '$1=="MATCHED_TOTAL"{print $2}')"
picks="$(printf '%s\n' "$selection" | awk -F'\t' '$1=="PICK"' | head -n "$max")"
picked_total="$(printf '%s\n' "$picks" | grep -c . || true)"
[ -z "$picks" ] && picked_total=0

# Usage log (on by default, opt out with --no-log). Plain text is fine here (not the
# security hook ledger) - a task brief on a personal machine isn't secret.
if [ "$nolog" -eq 0 ] && command -v jq >/dev/null 2>&1; then
  log_dir="$HOME/.claude/logs"
  mkdir -p "$log_dir" 2>/dev/null || true
  brief_snippet="$brief"
  [ "${#brief_snippet}" -gt 100 ] && brief_snippet="${brief_snippet:0:100}..."
  picked_names_json="$(printf '%s\n' "$picks" | awk -F'\t' 'NF{print $3}' | jq -R . | jq -sc .)"
  domain_tags_json="$(printf '%s\n' "$domain_csv" | tr ',' '\n' | jq -R . | jq -sc .)"
  ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  jq -nc --arg ts "$ts" --arg brief "$brief_snippet" --argjson domain_tags "$domain_tags_json" \
    --arg budget "$budget" --arg mode "$mode" --argjson picked "$picked_names_json" \
    '{ts: $ts, brief: $brief, domain_tags: $domain_tags, budget: $budget, mode: $mode, picked: $picked}' \
    >> "$log_dir/selector-usage.jsonl" 2>/dev/null || true
fi

if [ "$json" -eq 1 ]; then
  if ! command -v jq >/dev/null 2>&1; then echo "jq not found - install jq for --json output" >&2; exit 1; fi
  picked_json="[]"
  if [ -n "$picks" ]; then
    # Single jq invocation (not one per pick) - a per-line loop measured multiple seconds
    # of pure process-spawn overhead once the shortlist grows past a handful of entries.
    picked_json="$(printf '%s\n' "$picks" | awk -F'\t' 'NF{print $2"\t"$3"\t"$4"\t"$5}' | \
      jq -R -s '[split("\n")[] | select(length > 0) | split("\t") | {num: (.[0]|tonumber), name: .[1], group: (.[2]|tonumber), tags: (.[3] | split(","))}]')"
  fi
  domain_tags_json="$(printf '%s\n' "$domain_csv" | tr ',' '\n' | jq -R . | jq -sc .)"
  jq -nc --arg name "SREDNOFF OS selector" --arg brief "$brief" --argjson domain_tags "$domain_tags_json" \
    --arg budget "$budget" --argjson max "$max" --arg mode "$mode" \
    --argjson matched_total "${matched_total:-0}" --argjson picked_total "${picked_total:-0}" --argjson picked "$picked_json" \
    '{name: $name, brief: $brief, domain_tags: $domain_tags, budget: $budget, max: $max, mode: $mode,
      matched_total: $matched_total, picked_total: $picked_total, picked: $picked}'
else
  echo "SREDNOFF OS selector: mode=$mode budget=$budget tags=$domain_csv matched=${matched_total:-0} picked=${picked_total:-0}"
  if [ -n "$picks" ]; then
    printf '%s\n' "$picks" | awk -F'\t' '{printf "  G%s %s [%s]\n", $4, $3, $5}'
  else
    echo "  (no relevant matches - broaden the brief or pass --tags explicitly)"
  fi
fi
