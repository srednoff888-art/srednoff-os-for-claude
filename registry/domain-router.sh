#!/usr/bin/env bash
# SREDNOFF OS domain router (Linux/macOS port of domain-router.ps1). Classifies a TASK
# BRIEF (not just the project's static stack) into domains, then reports clarifying
# questions, canonical skill picks, and validation gates.
# Complements .claude/PROFILE.lock.md (generated once at init, per PROJECT). This router is
# dynamic and per-TASK: a web project can still get a 3D-domain answer if the brief is
# about a 3D configurator.
#
# Usage:
#   ./domain-router.sh --brief "make a 3D product configurator with React Three Fiber" --json
#   ./domain-router.sh --project . --brief "SEO audit before launch"
set -uo pipefail
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$script_dir/routing-lib.sh"

project="."; brief=""; json=0
while [ $# -gt 0 ]; do
  case "$1" in
    --project) project="$2"; shift 2 ;;
    --brief) brief="$2"; shift 2 ;;
    --json) json=1; shift ;;
    *) shift ;;
  esac
done

IFS='|' read -r mode budget _max _turbo _reason <<< "$(get_mode "$brief")"
mapfile -t domain_tags < <(get_domain_tags "$brief")

has_tag() { local needle="$1"; local t; for t in "${domain_tags[@]}"; do [ "$t" = "$needle" ] && return 0; done; return 1; }

questions=()
if has_tag "design" || has_tag "frontend"; then
  questions+=("Target user, product/site type, and desired visual impression?")
fi
if has_tag "3d"; then
  questions+=("Is this a product viewer, hero scene, configurator, or decorative scene? What is the performance budget (mobile fallback needed)?")
fi
if has_tag "seo"; then
  questions+=("Full technical audit or a targeted fix (which pages/keywords)?")
fi
if has_tag "amazon"; then
  questions+=("Public data/research only, or does this touch the real Seller Central account (money/inventory)?")
fi

gates=("lint-typecheck-build-tests" "code-review")
if has_tag "design" || has_tag "frontend"; then gates+=("accessibility" "responsive-screenshots"); fi
if has_tag "3d"; then gates+=("canvas-nonblank" "mobile-3d-fallback" "asset-size-report"); fi
if has_tag "security" || has_tag "amazon" || has_tag "trading"; then gates+=("security-review"); fi
if has_tag "seo"; then gates+=("search-policy-review"); fi

connectors=()
if has_tag "design" || has_tag "3d"; then connectors+=("figma" "magic:21st.dev"); fi
if has_tag "seo"; then connectors+=("dataforseo"); fi
if has_tag "amazon"; then connectors+=("merchant_amazon_*"); fi

# Canonical near-free skill picks (G1+G2 only - G3 stays "on demand", per Principle #1).
selector="$script_dir/select-skills.sh"
skill_picks=()
if [ -x "$selector" ] || [ -f "$selector" ]; then
  picks_json="$(bash "$selector" --brief "$brief" --max 10 --json --no-log 2>/dev/null || true)"
  if [ -n "$picks_json" ] && command -v jq >/dev/null 2>&1; then
    mapfile -t skill_picks < <(printf '%s' "$picks_json" | jq -r '.picked[] | select(.group <= 2) | .name' 2>/dev/null || true)
  fi
fi

domains_csv="$(printf '%s\n' "${domain_tags[@]}" | paste -sd, -)"

if [ "$json" -eq 1 ]; then
  if ! command -v jq >/dev/null 2>&1; then echo "jq not found - install jq for --json output" >&2; exit 1; fi
  domains_json="$(printf '%s\n' "${domain_tags[@]}" | jq -R . | jq -sc .)"
  questions_json="[]"; [ "${#questions[@]}" -gt 0 ] && questions_json="$(printf '%s\n' "${questions[@]}" | jq -R . | jq -sc .)"
  gates_json="$(printf '%s\n' "${gates[@]}" | jq -R . | jq -sc .)"
  connectors_json="[]"; [ "${#connectors[@]}" -gt 0 ] && connectors_json="$(printf '%s\n' "${connectors[@]}" | jq -R . | jq -sc .)"
  picks_json2="[]"; [ "${#skill_picks[@]}" -gt 0 ] && picks_json2="$(printf '%s\n' "${skill_picks[@]}" | jq -R . | jq -sc .)"
  jq -nc --arg name "SREDNOFF OS domain router" --arg project "$project" --arg brief "$brief" \
    --argjson domains "$domains_json" --arg mode "$mode" --arg budget "$budget" \
    --argjson questions "$questions_json" --argjson connectors "$connectors_json" \
    --argjson skill_picks "$picks_json2" --argjson gates "$gates_json" \
    '{name: $name, project: $project, brief: $brief, domains: $domains, mode: $mode, budget: $budget,
      questions: $questions, connector_suggestions: $connectors, skill_picks: $skill_picks,
      validation_gates: $gates,
      external_source_rule: "Any copy-adapt of external UI/3D/component code needs: license check, dependency-weight check, a11y/perf check, and provenance review (see CAPABILITY-INDEX.md + 70-skills-registry.md verification gate) before adoption."}'
else
  echo "SREDNOFF OS domains: $domains_csv | mode=$mode/$budget"
  if [ "${#questions[@]}" -gt 0 ]; then
    echo "Questions:"
    printf '  - %s\n' "${questions[@]}"
  fi
  if [ "${#skill_picks[@]}" -gt 0 ]; then
    echo "Skill picks:"
    printf '  - %s\n' "${skill_picks[@]}"
  fi
  gates_csv="$(printf '%s\n' "${gates[@]}" | paste -sd, -)"
  echo "Validation gates: $gates_csv"
fi
