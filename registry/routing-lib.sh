#!/usr/bin/env bash
# Shared routing helpers for SREDNOFF OS (Linux/macOS port of routing-lib.ps1).
# Source it: . "$(dirname "$0")/routing-lib.sh"
# Requires: grep -P (PCRE), awk (gawk or POSIX-compatible mawk both work - no gawk-only
# extensions used), jq (for JSON output in the scripts that source this, not used here).

GREP_BIN="${SREDNOFF_GREP_BIN:-grep}"

# --- Locale: routing is silently locale-dependent ------------------------------------
# Every classifier below pipes text into `grep -P`, sends stderr to /dev/null and reads a
# non-zero exit as "this rule did not match". But grep exits 2 on ERROR, not only 1 on
# no-match, and `grep -P` refuses to run at all under a locale it considers neither
# unibyte nor UTF-8 ("-P supports only unibyte and UTF-8 locales"). A router inherits
# whatever locale its caller had, so in such an environment EVERY rule reports "no match"
# and routing degrades to its fallbacks with no error anywhere: get_domain_tags() returns
# "general" for every brief, the quality mode is always "standard", and the selector hands
# back a generic default set.
#
# It is not only grep -P. CORE-300.md is UTF-8 with a large amount of Cyrillic, so the awk
# passes that parse and score catalog lines are locale-dependent too - under a non-UTF-8
# locale the same record can land in a different group (observed: a G2 entry scored as G3)
# and the selector returns a different set of skills for the same brief. The whole
# toolchain therefore needs one consistent UTF-8 locale, not a per-grep-call fix.
#
# Measured with GNU grep 3.0 and an empty LANG: run-evals.sh scored 20/46, and 46/46 with
# LC_ALL=C.UTF-8 - same code, same fixtures, only the locale.
#
# The probe leaves a correctly configured environment completely alone. It only exports a
# UTF-8 locale when the current one is already rejected by grep -P, i.e. when routing is
# provably broken as-is, so pinning can only improve the outcome.
# Deliberately duplicated from .claude/hooks/hook-lib.sh rather than shared: registry/
# scripts must not depend on the hooks directory (they ship and run independently).
_SREDNOFF_PCRE_OK=0
_srednoff_probe_pcre() {
  local loc
  # C.UTF-8 does not exist on macOS, en_US.UTF-8 does; C.utf8 is glibc's spelling.
  for loc in "" "C.UTF-8" "C.utf8" "en_US.UTF-8"; do
    if [ -z "$loc" ]; then
      if printf 'a' | "$GREP_BIN" -Pq -- 'a' 2>/dev/null; then
        _SREDNOFF_PCRE_OK=1; return 0
      fi
    elif printf 'a' | LC_ALL="$loc" "$GREP_BIN" -Pq -- 'a' 2>/dev/null; then
      # Exported, not applied per call: awk/sort/grep -E downstream must agree with grep -P.
      export LC_ALL="$loc"
      _SREDNOFF_PCRE_OK=1; return 0
    fi
  done
  return 1
}
_srednoff_probe_pcre || true

# Match the PCRE in $1 against text on stdin. Quiet; returns grep's own exit status.
# `--` matters: a pattern starting with "-" would otherwise be parsed as an option.
srednoff_grep_pcre() {
  "$GREP_BIN" -Pq -- "$1" 2>/dev/null
}

# Success = PCRE is usable. A caller that wants to warn instead of silently degrading
# (doctor, a router's --json output) can branch on this.
srednoff_pcre_ok() { [ "$_SREDNOFF_PCRE_OK" -eq 1 ]; }

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
    if printf '%s' "$brief_lower" | srednoff_grep_pcre "$pattern"; then
      printf '%s\n' "$tag"
      found=1
    fi
  done <<< "$_DOMAIN_RULES"
  [ "$found" -eq 0 ] && printf 'general\n'
}

_TURBO_PATTERN='(^|\s)turbo(\s|$)|\bturbo\s+mode\b|\bmode\s+turbo\b'
# Quality modes (v1.15, ported concept from srednoff-os/Codex sibling, see registry/quality-modes.json).
# critical = high-risk security/auth/payments/data work - gets a bigger budget than production.
# NOTE: bare '\baudit\b' was deliberately dropped - it false-positived on "SEO audit" /
# "content audit" (caught by quality-mode-fixtures.json production_launch). 'security'/
# 'compliance' already cover the intended security/compliance-audit case without it.
# 'migrat' is scoped to database/schema/data migrations, not generic content migration.
_CRITICAL_PATTERN='security|\bauth\b|oauth|payments?\b|(database|db|schema|data)\b.{0,20}migrat|migrat.{0,20}(database|db|schema)\b|data loss|irreversible|compliance|crypto'
# production = launch/deploy/release/SEO/PPC/growth/mobile/3D/architecture work, or a generic
# "go deep" synonym with no specific domain signal (falls through here, not to critical).
_PRODUCTION_PATTERN="production\\b|\\blaunch\\b|\\bdeploy(ment)?\\b|\\brelease\\b|\\bseo\\b|\\bppc\\b|growth\\b|mobile\\b|\\b3d\\b|architecture|maxim|do not skimp|don't skimp|deep research|full audit|максималь|не эконом|глубокий"
_FAST_PATTERN='\btypo\b|\bsmall fix\b|\bquick fix\b|\bformat(ting)?\b|\bquick check\b|\bminor docs?\b'

# Reads registry/quality-modes.json for validation_gates/group_policy per mode so those
# lists live in one place (the json), not duplicated here. Prints "gates|policy" (gates
# comma-joined). Falls back to empty on any error - non-security routing helper, fails open.
get_quality_mode_meta() {
  local mode_name="$1" json_path
  json_path="$(dirname "${BASH_SOURCE[0]}")/quality-modes.json"
  if ! command -v jq >/dev/null 2>&1 || [ ! -f "$json_path" ]; then printf '|\n'; return; fi
  jq -r --arg name "$mode_name" \
    '(.modes + [.turbo_override]) | map(select(.name == $name)) | .[0] // {validation_gates: [], group_policy: ""} | "\(.validation_gates | join(","))|\(.group_policy)"' \
    "$json_path" 2>/dev/null || printf '|\n'
}

# Prints "mode|budget|max_capabilities|turbo(0/1)|reason|legacy_mode|validation_gates|group_policy".
# TURBO fires ONLY on the literal word "turbo" - synonyms trigger production/critical, never
# turbo (Principle #1: quality first, but no silent uncontrolled scope growth).
get_mode() {
  local brief_lower is_turbo=0 is_critical=0 is_production=0 is_fast=0
  local mode legacy_mode budget max_cap reason gates policy
  brief_lower="$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')"
  if printf '%s' "$brief_lower" | srednoff_grep_pcre "$_TURBO_PATTERN"; then is_turbo=1; fi
  if printf '%s' "$brief_lower" | srednoff_grep_pcre "$_CRITICAL_PATTERN"; then is_critical=1; fi
  if [ "$is_critical" -eq 0 ] && printf '%s' "$brief_lower" | srednoff_grep_pcre "$_PRODUCTION_PATTERN"; then is_production=1; fi
  if [ "$is_turbo" -eq 0 ] && [ "$is_critical" -eq 0 ] && [ "$is_production" -eq 0 ] \
     && printf '%s' "$brief_lower" | srednoff_grep_pcre "$_FAST_PATTERN"; then is_fast=1; fi

  if [ "$is_turbo" -eq 1 ]; then
    mode="turbo"; legacy_mode="turbo"; budget="turbo"; max_cap=48; reason="explicit TURBO trigger"
  elif [ "$is_critical" -eq 1 ]; then
    mode="critical"; legacy_mode="deep"; budget="deep"; max_cap=32; reason="high-risk security/auth/payments/data trigger"
  elif [ "$is_production" -eq 1 ]; then
    mode="production"; legacy_mode="deep"; budget="deep"; max_cap=24; reason="launch/deploy/SEO/growth/production-facing trigger"
  elif [ "$is_fast" -eq 1 ]; then
    mode="fast"; legacy_mode="normal"; budget="lean"; max_cap=8; reason="small low-risk change trigger"
  else
    mode="standard"; legacy_mode="normal"; budget="balanced"; max_cap=16; reason="normal scoped work"
  fi
  IFS='|' read -r gates policy <<< "$(get_quality_mode_meta "$mode")"
  printf '%s|%s|%s|%s|%s|%s|%s|%s\n' "$mode" "$budget" "$max_cap" "$is_turbo" "$reason" "$legacy_mode" "$gates" "$policy"
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
