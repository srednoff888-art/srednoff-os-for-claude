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
quality_mode_fixtures="$registry/evals/quality-mode-fixtures.json"
domain_fixtures="$registry/evals/domain-fixtures.json"
selector_fixtures="$registry/evals/selector-fixtures.json"
secret_fixtures="$registry/evals/secret-pattern-fixtures.json"
source_ranker_fixtures="$registry/evals/source-ranker-fixtures.json"
source_ranker="$registry/source-ranker.sh"
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

if [ -f "$quality_mode_fixtures" ]; then
  while IFS=$'\t' read -r id brief expected_mode expected_legacy expected_max; do
    [ -z "$id" ] && continue
    out="$(bash "$mode_router" --brief "$brief" --json 2>/dev/null)"
    got_mode="$(printf '%s' "$out" | jq -r '.mode // "ERROR"')"
    got_legacy="$(printf '%s' "$out" | jq -r '.legacy_mode // "ERROR"')"
    got_max="$(printf '%s' "$out" | jq -r '.max_capabilities // "ERROR"')"
    pass=0
    [ "$got_mode" = "$expected_mode" ] && [ "$got_legacy" = "$expected_legacy" ] && [ "$got_max" = "$expected_max" ] && pass=1
    add_result "quality-mode" "$id" "$pass" "mode=$expected_mode,legacy=$expected_legacy,max=$expected_max" "mode=$got_mode,legacy=$got_legacy,max=$got_max"
  done < <(jq -r '.[] | [.id, .brief, .expectedMode, .expectedLegacyMode, .expectedMaxCapabilities] | @tsv' "$quality_mode_fixtures" | strip_cr)
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

if [ -f "$source_ranker_fixtures" ] && [ -f "$source_ranker" ]; then
  while IFS= read -r fixture; do
    [ -z "$fixture" ] && continue
    id="$(printf '%s' "$fixture" | jq -r '.id')"
    brief="$(printf '%s' "$fixture" | jq -r '.brief')"
    out="$(bash "$source_ranker" --brief "$brief" --json 2>/dev/null)"
    has_expected_top="$(printf '%s' "$fixture" | jq -r 'has("expectedTop")')"
    has_id_present="$(printf '%s' "$fixture" | jq -r 'has("expectedIdPresent")')"
    has_domains="$(printf '%s' "$fixture" | jq -r 'has("expectedDomains")')"

    pass=0; expected=""; got=""
    if [ "$has_expected_top" = "true" ]; then
      top_id="$(printf '%s' "$out" | jq -r '.ranked_sources[0].id // ""')"
      expected_tops_csv="$(printf '%s' "$fixture" | jq -r 'if (.expectedTop | type) == "array" then (.expectedTop | join(",")) else .expectedTop end')"
      IFS=',' read -ra expected_tops <<< "$expected_tops_csv"
      for e in ${expected_tops[@]+"${expected_tops[@]}"}; do [ "$e" = "$top_id" ] && pass=1; done
      expected="top in [$expected_tops_csv]"; got="top=$top_id"
    elif [ "$has_id_present" = "true" ]; then
      expected_id="$(printf '%s' "$fixture" | jq -r '.expectedIdPresent')"
      ids_csv="$(printf '%s' "$out" | jq -r '[.ranked_sources[].id] | join(",")')"
      id_present=0
      IFS=',' read -ra ids_arr <<< "$ids_csv"
      for g in ${ids_arr[@]+"${ids_arr[@]}"}; do [ "$g" = "$expected_id" ] && id_present=1; done
      pass=$id_present
      expected="id present: $expected_id"; got="ids=$ids_csv"
      has_gate_check="$(printf '%s' "$fixture" | jq -r 'has("expectedGateOnId")')"
      if [ "$id_present" -eq 1 ] && [ "$has_gate_check" = "true" ]; then
        expected_gate="$(printf '%s' "$fixture" | jq -r '.expectedGateOnId.gate')"
        gates_csv="$(printf '%s' "$out" | jq -r --arg id "$expected_id" '[.ranked_sources[] | select(.id == $id) | .gates[]] | join(",")')"
        gate_present=0
        IFS=',' read -ra gates_arr <<< "$gates_csv"
        for g in ${gates_arr[@]+"${gates_arr[@]}"}; do [ "$g" = "$expected_gate" ] && gate_present=1; done
        pass=$gate_present
        expected="$expected; gate '$expected_gate' on $expected_id"; got="$got; gates=$gates_csv"
      fi
    elif [ "$has_domains" = "true" ]; then
      expected_domains_csv="$(printf '%s' "$fixture" | jq -r '.expectedDomains | join(",")')"
      got_domains_csv="$(printf '%s' "$out" | jq -r '.domains | join(",")')"
      IFS=',' read -ra expected_domains_arr <<< "$expected_domains_csv"
      IFS=',' read -ra got_domains_arr <<< "$got_domains_csv"
      for e in ${expected_domains_arr[@]+"${expected_domains_arr[@]}"}; do
        for g in ${got_domains_arr[@]+"${got_domains_arr[@]}"}; do
          [ "$e" = "$g" ] && pass=1
        done
      done
      expected="domain in [$expected_domains_csv]"; got="domains=$got_domains_csv"
    fi

    add_result "source-ranker" "$id" "$pass" "$expected" "$got"
  done < <(jq -c '.[]' "$source_ranker_fixtures" | strip_cr)
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
