#!/usr/bin/env bash
# SREDNOFF OS status one-liner (Linux/macOS port of status.ps1). Single source of truth
# instead of ad-hoc verification commands typed fresh each session.
#
# Usage:
#   ./status.sh --project "/path/to/project"
#   ./status.sh --project . --json
set -uo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
project="."; json=0
while [ $# -gt 0 ]; do
  case "$1" in
    --project) project="$2"; shift 2 ;;
    --json) json=1; shift ;;
    *) shift ;;
  esac
done

claude_home="$HOME/.claude"
registry="$claude_home/registry"
version_file="$registry/version.json"
core_catalog="$registry/CORE-300.md"
global_settings="$claude_home/settings.json"
project_root="$(cd "$project" 2>/dev/null && pwd)"
[ -z "$project_root" ] && project_root="$project"

version="unknown"
if [ -f "$version_file" ] && command -v jq >/dev/null 2>&1; then
  version="$(jq -r '.version // "unknown"' "$version_file" 2>/dev/null || echo unknown)"
fi

kernel_count=0
[ -f "$core_catalog" ] && kernel_count="$(grep -Ec '^[[:space:]]*[0-9]+\.[[:space:]]+`' "$core_catalog" || true)"

hooks_ok=false
if [ -f "$global_settings" ] && command -v jq >/dev/null 2>&1; then
  has_session_start="$(jq -e '.hooks.SessionStart' "$global_settings" >/dev/null 2>&1 && echo 1 || echo 0)"
  has_status_line="$(jq -e '.statusLine' "$global_settings" >/dev/null 2>&1 && echo 1 || echo 0)"
  [ "$has_session_start" = "1" ] && [ "$has_status_line" = "1" ] && hooks_ok=true
fi

project_claude_md="$project_root/CLAUDE.md"
project_banner_ok=false
if [ -f "$project_claude_md" ] && grep -q "SREDNOFF OS" "$project_claude_md" 2>/dev/null; then
  project_banner_ok=true
fi

. "$script_dir/rule-file-list.sh"
rule_files=("${RULE_FILE_NAMES[@]}")
rules_present=0
for r in "${rule_files[@]}"; do
  [ -f "$project_root/.claude/rules/$r.md" ] && rules_present=$((rules_present + 1))
done
lock_ok=false
[ -f "$project_root/.claude/PROFILE.lock.md" ] && lock_ok=true

failed=()
[ "$hooks_ok" = "true" ] || failed+=("GlobalHooks")
[ -f "$core_catalog" ] || failed+=("Registry")
[ "$project_banner_ok" = "true" ] || failed+=("ProjectBanner")
[ "$rules_present" -eq "${#rule_files[@]}" ] || failed+=("ProjectRules")
[ "$lock_ok" = "true" ] || failed+=("ProjectLock")

status="OK"; [ "${#failed[@]}" -gt 0 ] && status="WARN"
project_state="SYNC_NEEDED"
[ "$project_banner_ok" = "true" ] && [ "$rules_present" -eq "${#rule_files[@]}" ] && project_state="OK"

if [ "$json" -eq 1 ]; then
  if ! command -v jq >/dev/null 2>&1; then echo "jq not found - install jq for --json output" >&2; exit 1; fi
  failed_json="[]"; [ "${#failed[@]}" -gt 0 ] && failed_json="$(printf '%s\n' "${failed[@]}" | jq -R . | jq -sc .)"
  jq -nc --arg name "SREDNOFF OS" --arg version "$version" --arg status "$status" --arg project "$project_root" \
    --arg project_state "$project_state" --arg rules_present "$rules_present/${#rule_files[@]}" \
    --argjson registry_records "${kernel_count:-0}" --argjson lock_present "$lock_ok" --argjson failed "$failed_json" \
    '{name: $name, version: $version, status: $status, project: $project, project_state: $project_state,
      rules_present: $rules_present, registry_records: $registry_records, lock_present: $lock_present, failed_checks: $failed}'
  exit 0
fi

failed_text=""
[ "${#failed[@]}" -gt 0 ] && failed_text=" | failed=$(printf '%s' "${failed[*]}" | tr ' ' ',')"
echo "SREDNOFF OS $version loaded: $status | project=$project_state | rules=$rules_present/${#rule_files[@]} | registry=${kernel_count:-0} | lock=$lock_ok$failed_text"
