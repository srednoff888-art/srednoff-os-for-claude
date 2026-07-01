#!/usr/bin/env bash
# Shared routing helpers for SREDNOFF OS (Linux/macOS port of routing-lib.ps1).
# Source it: . "$(dirname "$0")/routing-lib.sh"
# Requires: grep -P (PCRE), awk (gawk or POSIX-compatible mawk both work - no gawk-only
# extensions used), jq (for JSON output in the scripts that source this, not used here).

GREP_BIN="${SREDNOFF_GREP_BIN:-grep}"

# tag|combined-alternation-regex pairs, one per line. Same keyword sets as routing-lib.ps1.
_DOMAIN_RULES='web|web app|website|landing|frontend app|browser
frontend|frontend|\bui\b|react\b|vue\b|angular\b|next\.?js|component
backend|backend|\bapi\b|server\b|fastapi|django|express|endpoint
3d|\b3d\b|three\.?js|\br3f\b|react three fiber|webgl|webgpu|gltf|glb|babylon|shader|configurator
animation|animation|motion\b|gsap|framer motion|scroll.?trigger|transition
design|design system|ui kit|figma|shadcn|tailwind|visual design|brand\b
seo|\bseo\b|sitemap|hreflang|schema\.org|\bserp\b|crawl|indexing
marketing|marketing|campaign|email sequence|\bads\b|\bppc\b|growth\b
sales|\bsales\b|outreach|\blead\b|\bcrm\b|prospect
amazon|amazon\b|\bfba\b|\basin\b|seller central|sp-api
trading|trading|backtest|exchange api|ccxt|portfolio|risk manager
ml|machine learning|\bml\b|model training|pytorch|tensorflow|\bllm\b
ai|\bai\b|openai|anthropic|claude|\bgpt\b|\brag\b|embedding
data|database|\bsql\b|postgres|data pipeline|\betl\b|analytics
infra|infrastructure|docker|kubernetes|terraform|cloud\b
devops|devops|ci/?cd|deploy|pipeline|github actions
security|security|\bauth\b|oauth|vulnerability|penetration|secrets?\b
test|\btest|testing|\be2e\b|playwright|cypress|unit test
mobile|mobile\b|\bios\b|android\b|\bexpo\b|react native|swiftui
docs|documentation|readme|changelog|api docs
legal|legal\b|contract\b|compliance|gdpr|privacy policy
finance|finance\b|billing|invoice|accounting|pricing'

# Prints one matched domain tag per line (already deduped: one rule per tag). Falls back
# to "general" if nothing matched, same as Get-DomainTags in routing-lib.ps1.
# PERFORMANCE NOTE: this spawns one grep -P process per tag (~20). On native Linux, fork+exec
# is ~1-3ms so the whole function costs well under 100ms - fine for a per-task call. Measured
# ~1.9s during development, but that was under Windows/Cygwin (Git Bash), where each process
# spawn alone costs ~130ms regardless of the work done - a test-environment artifact, not a
# reflection of real Linux deployment cost. Kept as separate grep -P calls (rather than
# collapsing into one awk pass) to preserve exact \b word-boundary semantics without
# introducing a regex-rewrite risk for a saving that doesn't exist on the target platform.
get_domain_tags() {
  local brief_lower found=0 tag pattern
  brief_lower="$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')"
  while IFS='|' read -r tag pattern; do
    [ -z "$tag" ] && continue
    if printf '%s' "$brief_lower" | "$GREP_BIN" -Pq "$pattern" 2>/dev/null; then
      printf '%s\n' "$tag"
      found=1
    fi
  done <<< "$_DOMAIN_RULES"
  [ "$found" -eq 0 ] && printf 'general\n'
}

_TURBO_PATTERN='(^|\s)turbo(\s|$)|\bturbo\s+mode\b|\bmode\s+turbo\b'
_DEEP_PATTERN="maxim|do not skimp|don't skimp|production\\b|security audit|architecture|migration|launch\\b|deep research|full audit|максималь|не эконом|глубокий"

# Prints "mode|budget|max_capabilities|turbo(0/1)|reason". TURBO fires ONLY on the literal
# word "turbo" - synonyms like "maximally"/"production"/"security audit" trigger "deep",
# never "turbo" (Principle #1: quality first, but no silent uncontrolled scope growth).
get_mode() {
  local brief_lower is_turbo=0 is_deep=0 mode budget max_cap reason
  brief_lower="$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')"
  if printf '%s' "$brief_lower" | "$GREP_BIN" -Pq "$_TURBO_PATTERN" 2>/dev/null; then is_turbo=1; fi
  if printf '%s' "$brief_lower" | "$GREP_BIN" -Pq "$_DEEP_PATTERN" 2>/dev/null; then is_deep=1; fi
  if [ "$is_turbo" -eq 1 ]; then
    mode="turbo"; budget="turbo"; max_cap=48; reason="explicit TURBO trigger"
  elif [ "$is_deep" -eq 1 ]; then
    mode="deep"; budget="deep"; max_cap=24; reason="high-value/deep-work trigger without TURBO"
  else
    mode="normal"; budget="balanced"; max_cap=16; reason="normal scoped work"
  fi
  printf '%s|%s|%s|%s|%s\n' "$mode" "$budget" "$max_cap" "$is_turbo" "$reason"
}

# Budget quotas: share of the shortlist that should come from G1/G2/G3.
budget_quota() {
  local budget="$1" group="$2"
  case "$budget" in
    lean)     case "$group" in 1) echo 0.80;; 2) echo 0.20;; 3) echo 0.00;; esac ;;
    deep)     case "$group" in 1) echo 0.35;; 2) echo 0.45;; 3) echo 0.20;; esac ;;
    turbo)    case "$group" in 1) echo 0.20;; 2) echo 0.45;; 3) echo 0.35;; esac ;;
    *)        case "$group" in 1) echo 0.50;; 2) echo 0.40;; 3) echo 0.10;; esac ;; # balanced (default)
  esac
}

# Counts non-empty lines in a report string, treating an empty string as 0 (plain
# `grep -c .` on an empty string reports 1, not 0 - this guards that off-by-one once instead
# of at every call site). Extracted via refactoring review, 2026-07-01: the same 3-line
# "build report, grep -c, guard empty" idiom was repeated 4x in validate-catalog-format.sh
# and audit-registry.sh.
count_nonempty_lines() {
  [ -z "$1" ] && { echo 0; return; }
  printf '%s\n' "$1" | grep -c .
}

# Builds a JSON array from bash positional args, defaulting to "[]" for zero args. Extracted
# via refactoring review, 2026-07-01: domain-router.sh repeated this "array or empty array"
# pattern 4x with slightly inconsistent guarding.
bash_arr_to_json() {
  [ $# -eq 0 ] && { echo "[]"; return; }
  printf '%s\n' "$@" | jq -R . | jq -sc .
}

# Parses CORE-300.md into TSV rows: num<TAB>name<TAB>group<TAB>tags(comma-joined)<TAB>line
# POSIX-awk compatible (no gawk-only 3-arg match()) so it runs under mawk too. No JSON cache
# needed here (unlike the PowerShell port): awk parses ~2000 lines in well under 100ms, and
# bash/awk process-startup overhead is negligible compared to PowerShell's ~0.5-0.8s floor.
get_core_catalog() {
  local core_path="$1"
  awk '
    {
      header = toupper($0)
      gsub(/[^A-Z0-9]/, "", header)
      if (header == "GROUP1" || header == "G1") { group = 1; next }
      if (header == "GROUP2" || header == "G2") { group = 2; next }
      if (header == "GROUP3" || header == "G3") { group = 3; next }
    }
    match($0, /^[ \t]*[0-9]+\.[ \t]+`[^`]+`/) {
      line2 = $0
      tmp = line2
      sub(/^[ \t]*/, "", tmp)
      split(tmp, a, ".")
      num = a[1]
      bt1 = index(line2, "`")
      rest1 = substr(line2, bt1 + 1)
      bt2 = index(rest1, "`")
      name = substr(rest1, 1, bt2 - 1)
      rest = substr(rest1, bt2 + 1)
      tags = ""
      r = rest
      while (match(r, /\[[a-zA-Z0-9]+\]/)) {
        tag = substr(r, RSTART + 1, RLENGTH - 2)
        tags = (tags == "" ? tag : tags "," tag)
        r = substr(r, RSTART + RLENGTH)
      }
      full = line2
      gsub(/\t/, " ", full)
      print num "\t" name "\t" (group + 0) "\t" tags "\t" full
    }
  ' "$core_path"
}
