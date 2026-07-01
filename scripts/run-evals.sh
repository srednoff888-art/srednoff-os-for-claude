#!/usr/bin/env bash
# SREDNOFF OS eval runner (Linux/macOS port of run-evals.ps1). Regression-tests the domain
# router and selector against fixed briefs so a routing/tag change can't silently break
# skill selection. Requires: jq.
#
# Usage:
#   ./run-evals.sh
#   ./run-evals.sh --json
set -uo pipefail

json=0
[ "${1:-}" = "--json" ] && json=1

registry="$HOME/.claude/registry"
mode_router="$registry/mode-router.sh"
domain_router="$registry/domain-router.sh"
selector="$registry/select-skills.sh"
mode_fixtures="$registry/evals/mode-fixtures.json"
domain_fixtures="$registry/evals/domain-fixtures.json"
selector_fixtures="$registry/evals/selector-fixtures.json"
secret_fixtures="$registry/evals/secret-pattern-fixtures.json"
hook_lib="$HOME/.claude/templates/claude-md-os/.claude/hooks/hook-lib.sh"

if ! command -v jq >/dev/null 2>&1; then echo "jq not found - required for run-evals.sh" >&2; exit 1; fi

pass_count=0; total=0
results=()   # each entry: suite|id|pass(0/1)|expected|got

add_result() {
  results+=("$1|$2|$3|$4|$5")
  total=$((total + 1))
  [ "$3" -eq 1 ] && pass_count=$((pass_count + 1))
}

# Strip any stray CR bytes (defensive: a fixture file or jq binary that emits CRLF would
# otherwise leave \r glued to the last TSV field, breaking string equality downstream).
strip_cr() { tr -d '\r'; }

# Secret-pattern regression (real gitleaks/vendor-shaped fixtures, not invented examples -
# closes a gap found in critical review: patterns were never validated against an
# independent corpus, only against test strings the same author who wrote the regex wrote).
if [ -f "$secret_fixtures" ] && [ -f "$hook_lib" ]; then
  . "$hook_lib"
  while IFS=$'\t' read -r id text expect; do
    [ -z "$id" ] && continue
    hits=(); while IFS= read -r _line; do hits+=("$_line"); done < <(find_secret_signals "$text")
    got=0; [ "${#hits[@]}" -gt 0 ] && got=1
    pass=0; [ "$got" -eq "$expect" ] && pass=1
    add_result "secret-pattern" "$id" "$pass" "match=$expect" "match=$got (${hits[*]:-})"
  done < <(jq -r '.[] | [.id, .text, (if .expectMatch then 1 else 0 end)] | @tsv' "$secret_fixtures" | strip_cr)
fi

if [ -f "$mode_fixtures" ]; then
  while IFS=$'\t' read -r id brief expected_mode; do
    [ -z "$id" ] && continue
    out="$(bash "$mode_router" --brief "$brief" --json 2>/dev/null)"
    got_mode="$(printf '%s' "$out" | jq -r '.mode // "ERROR"')"
    pass=0; [ "$got_mode" = "$expected_mode" ] && pass=1
    add_result "mode" "$id" "$pass" "$expected_mode" "$got_mode"
  done < <(jq -r '.[] | [.id, .brief, .expectedMode] | @tsv' "$mode_fixtures" | strip_cr)
fi

if [ -f "$domain_fixtures" ]; then
  while IFS=$'\t' read -r id brief expected_domains_csv; do
    [ -z "$id" ] && continue
    out="$(bash "$domain_router" --brief "$brief" --json 2>/dev/null)"
    got_csv="$(printf '%s' "$out" | jq -r '.domains | join(",")')"
    pass=0
    IFS=',' read -ra expected_arr <<< "$expected_domains_csv"
    IFS=',' read -ra got_arr <<< "$got_csv"
    for e in ${expected_arr[@]+"${expected_arr[@]}"}; do
      for g in ${got_arr[@]+"${got_arr[@]}"}; do
        [ "$e" = "$g" ] && pass=1
      done
    done
    add_result "domain" "$id" "$pass" "$expected_domains_csv" "$got_csv"
  done < <(jq -r '.[] | [.id, .brief, (.expectedDomains | join(","))] | @tsv' "$domain_fixtures" | strip_cr)
fi

if [ -f "$selector_fixtures" ]; then
  while IFS=$'\t' read -r id brief budget expected_any_csv; do
    [ -z "$id" ] && continue
    out="$(bash "$selector" --brief "$brief" --budget "$budget" --json --no-log 2>/dev/null)"
    got_names_csv="$(printf '%s' "$out" | jq -r '[.picked[].name] | join(",")')"
    pass=0
    IFS=',' read -ra expected_arr <<< "$expected_any_csv"
    IFS=',' read -ra got_arr <<< "$got_names_csv"
    for e in ${expected_arr[@]+"${expected_arr[@]}"}; do
      for g in ${got_arr[@]+"${got_arr[@]}"}; do
        [ "$e" = "$g" ] && pass=1
      done
    done
    add_result "selector" "$id" "$pass" "$expected_any_csv" "$got_names_csv"
  done < <(jq -r '.[] | [.id, .brief, .budget, (.expectedAny | join(","))] | @tsv' "$selector_fixtures" | strip_cr)
fi

# Quota invariant: "lean" budget must never surface a G3 (heavyweight) record.
lean_out="$(bash "$selector" --brief "add Stripe checkout to the Next.js app" --budget lean --max 12 --json --no-log 2>/dev/null)"
lean_g3_count="$(printf '%s' "$lean_out" | jq '[.picked[] | select(.group == 3)] | length')"
inv_pass=0; [ "${lean_g3_count:-1}" -eq 0 ] && inv_pass=1
add_result "invariant" "lean_budget_no_g3" "$inv_pass" "0 G3 records" "$lean_g3_count G3 records"

if [ "$json" -eq 1 ]; then
  results_json="[]"
  if [ "${#results[@]}" -gt 0 ]; then
    results_json="$(for r in "${results[@]}"; do
      IFS='|' read -r suite id pass expected got <<< "$r"
      jq -nc --arg suite "$suite" --arg id "$id" --argjson pass "$([ "$pass" -eq 1 ] && echo true || echo false)" \
        --arg expected "$expected" --arg got "$got" \
        '{suite: $suite, id: $id, pass: $pass, expected: $expected, got: $got}'
    done | jq -sc '.')"
  fi
  jq -nc --argjson pass "$pass_count" --argjson total "$total" --argjson results "$results_json" \
    '{pass: $pass, total: $total, results: $results}'
  exit 0
fi

for r in "${results[@]}"; do
  IFS='|' read -r suite id pass expected got <<< "$r"
  mark="FAIL"; [ "$pass" -eq 1 ] && mark="OK  "
  echo "[$mark] $suite/$id  expected one of: $expected"
  [ "$pass" -eq 0 ] && echo "        got: $got"
done
echo ""
echo "SREDNOFF OS evals: $pass_count/$total passed"
[ "$pass_count" -lt "$total" ] && exit 1
exit 0
