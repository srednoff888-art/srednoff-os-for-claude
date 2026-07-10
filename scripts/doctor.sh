#!/usr/bin/env bash
# SREDNOFF OS doctor (Linux/macOS port of doctor.ps1): one command for status + structural
# check + evals + safe auto-repair.
#
# Usage:
#   ./doctor.sh --project "/path/to/project" --run-evals --fix-safe
set -uo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
registry="$HOME/.claude/registry"

project="."; json=0; run_evals=0; fix_safe=0
while [ $# -gt 0 ]; do
  case "$1" in
    --project) project="$2"; shift 2 ;;
    --json) json=1; shift ;;
    --run-evals) run_evals=1; shift ;;
    --fix-safe) fix_safe=1; shift ;;
    *) shift ;;
  esac
done

project_root="$(cd "$project" 2>/dev/null && pwd)"
[ -z "$project_root" ] && project_root="$project"

check_names=(); check_status=(); check_detail=()
add_check() { check_names+=("$1"); check_status+=("$2"); check_detail+=("$3"); }

# 0. jq dependency check (closes: "silent fail-open when jq is missing" found via
# security-audit review, 2026-07-01). Every bash hook that scans for secrets/dangerous
# commands hard-depends on jq to parse its JSON input; without it, `command -v jq || exit 0`
# makes the hook silently allow EVERYTHING through with zero output and zero warning. The
# hook-canary check below would eventually catch this too (as a generic "not denied"
# failure), but this dedicated check gives the actual, specific root cause immediately.
if command -v jq >/dev/null 2>&1; then
  add_check "jq-dependency" "OK" "jq found - bash secret/danger hooks can parse their JSON input"
else
  add_check "jq-dependency" "FAIL" "jq NOT FOUND - bash hooks (block-dangerous-bash.sh, protect-secrets.sh, scan-prompt-secrets.sh) silently fail OPEN (allow everything) without it. Install: apt/dnf/pacman install jq, or brew install jq on macOS."
fi

# 1. Status one-liner
status_out="$(bash "$script_dir/status.sh" --project "$project_root" 2>&1)"
status_check="WARN"; printf '%s' "$status_out" | grep -q "loaded: OK" && status_check="OK"
add_check "status" "$status_check" "$status_out"

# 2. Structural file check
struct_out="$(bash "$script_dir/check-claude-md-os.sh" "$project_root" 2>&1)"
struct_ok=0; printf '%s' "$struct_out" | grep -q "All required files present" && struct_ok=1
if [ "$struct_ok" -eq 1 ]; then
  add_check "structure" "OK" "all files present"
else
  missing_lines="$(printf '%s' "$struct_out" | grep "MISS" | paste -sd';' -)"
  add_check "structure" "FAIL" "$missing_lines"
fi

# 2a2. Template drift (project's PROFILE.lock.md "OS version" stamp vs the current
# registry/version.json). Informational only (WARN, never FAIL) - an older stamp just
# means the project hasn't been synced since a newer OS version shipped; run
# apply-os-all.sh --sync (or init-claude-project.sh directly) to refresh it.
lock_path="$project_root/.claude/PROFILE.lock.md"
version_file="$registry/version.json"
if [ -f "$lock_path" ] && [ -f "$version_file" ] && command -v jq >/dev/null 2>&1; then
  current_version="$(jq -r '.version // "unknown"' "$version_file" 2>/dev/null || echo "unknown")"
  project_version="$(grep -m1 '^OS version: ' "$lock_path" | sed -E 's/^OS version: ([^ ]+).*/\1/')"
  if [ -n "$project_version" ]; then
    if [ "$project_version" = "$current_version" ]; then
      add_check "template-drift" "OK" "project=$project_version current=$current_version"
    else
      add_check "template-drift" "WARN" "project=$project_version current=$current_version - run apply-os-all.sh --sync or re-run init to refresh"
    fi
  else
    add_check "template-drift" "WARN" "PROFILE.lock.md has no OS version stamp (generated before this check existed) - re-run gen-profile-lock or init to add it"
  fi
fi

# 2b. Registry audit (cheap, local-only, no network - always safe to run)
if command -v jq >/dev/null 2>&1; then
  audit_out="$(bash "$registry/audit-registry.sh" --json 2>/dev/null)"
  dup_count="$(printf '%s' "$audit_out" | jq -r '.duplicate_count // 0')"
  total_records="$(printf '%s' "$audit_out" | jq -r '.total_records // 0')"
  audit_status="OK"; [ "${dup_count:-0}" -gt 0 ] && audit_status="WARN"
  add_check "registry-audit" "$audit_status" "records=$total_records; duplicates=$dup_count"

  # 2c. Catalog format validation (catches malformed lines that would silently vanish from parsing)
  validate_out="$(bash "$registry/validate-catalog-format.sh" --json 2>/dev/null)"
  issues_count="$(printf '%s' "$validate_out" | jq -r '.issues | length')"
  parsed_count="$(printf '%s' "$validate_out" | jq -r '.total_parsed // 0')"
  validate_status="OK"; [ "${issues_count:-0}" -gt 0 ] && validate_status="WARN"
  add_check "catalog-format" "$validate_status" "parsed=$parsed_count; issues=$issues_count"
  # 2c2. Catalog JSON export drift gate (CORE-300.json must stay in sync with CORE-300.md;
  # see registry/RFC-CATALOG-JSON.md - external consumers read the JSON directly).
  if [ -f "$registry/gen-catalog-json.sh" ]; then
    catalog_json_out="$(bash "$registry/gen-catalog-json.sh" --check 2>&1)"
    catalog_json_status="OK"
    case "$catalog_json_out" in *"OK - CORE-300.json is in sync"*) ;; *) catalog_json_status="WARN" ;; esac
    add_check "catalog-json" "$catalog_json_status" "$catalog_json_out"
  fi
else
  add_check "registry-audit" "WARN" "jq not found - skipped"
  add_check "catalog-format" "WARN" "jq not found - skipped"
fi

# 2c3. Skills-library metadata smoke check (v1.17, Stage 3 skill import) - name/description/
# frontmatter validity for the curated, installable subset of the catalog. Runs against
# the TEMPLATE root, not the project being doctored - skills-library lives in the template,
# not per-project.
skills_lib_script="$script_dir/validate-skills-library.sh"
if [ -f "$skills_lib_script" ] && command -v jq >/dev/null 2>&1; then
  skills_lib_out="$(bash "$skills_lib_script" --json 2>/dev/null)"
  skills_lib_ok="$(printf '%s' "$skills_lib_out" | jq -r '.ok // 0')"
  skills_lib_failed="$(printf '%s' "$skills_lib_out" | jq -r '.failed // 0')"
  skills_lib_status="OK"; [ "${skills_lib_failed:-0}" -gt 0 ] && skills_lib_status="FAIL"
  add_check "skills-library" "$skills_lib_status" "ok=$skills_lib_ok; failed=$skills_lib_failed"
fi

# 2d. Registry/template version control. Auto-commits any pending changes so a bad edit is
# always revertible via git, WITHOUT relying on remembering to commit by hand.
invoke_auto_commit() {
  local repo_path="$1" label="$2"
  [ -d "$repo_path/.git" ] || { echo "no-repo"; return; }
  (
    cd "$repo_path" || exit 0
    dirty="$(git status --porcelain 2>/dev/null)"
    if [ -z "$dirty" ]; then echo "clean"; exit 0; fi
    git add -A >/dev/null 2>&1
    ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    git -c user.email="srednoff-os@local" -c user.name="Srednoff OS doctor" commit -q -m "doctor auto-commit ($label): $ts" >/dev/null 2>&1
    echo "committed"
  )
}
registry_git="$(invoke_auto_commit "$registry" "registry")"
template_git="$(invoke_auto_commit "$HOME/.claude/templates/claude-md-os" "template")"
add_check "version-control" "OK" "registry=$registry_git; template=$template_git"

# 2e. Hook canary test (closes: "fail-open hooks break silently with zero visibility").
# Feeds each hook a KNOWN-bad synthetic input and confirms it still denies/blocks.
hooks_dir="$project_root/.claude/hooks"
if [ -f "$hooks_dir/block-dangerous-bash.sh" ]; then
  canary_fails=()
  r1="$(echo '{"tool_input":{"command":"mkfs.ext4 /dev/sda1"}}' | bash "$hooks_dir/block-dangerous-bash.sh" 2>/dev/null)"
  printf '%s' "$r1" | grep -q "deny" || canary_fails+=("block-dangerous-bash: known-dangerous command was NOT denied")
  r2="$(echo '{"tool_input":{"file_path":"app/.env"}}' | bash "$hooks_dir/protect-secrets.sh" 2>/dev/null)"
  printf '%s' "$r2" | grep -q "deny" || canary_fails+=("protect-secrets: known-secret path was NOT denied")
  r3="$(echo '{"prompt":"sk-ant-api03-abcdefghijklmnopqrstuvwx"}' | bash "$hooks_dir/scan-prompt-secrets.sh" 2>/dev/null)"
  printf '%s' "$r3" | grep -q '"decision":"block"' || canary_fails+=("scan-prompt-secrets: known-secret prompt was NOT blocked")
  if [ "${#canary_fails[@]}" -eq 0 ]; then
    add_check "hook-canary" "OK" "3/3 canary triggers still deny/block as expected"
  else
    add_check "hook-canary" "FAIL" "$(printf '%s; ' "${canary_fails[@]}")"
  fi
fi

# 2f. PROFILE.lock enforcement gate canary (deny -> mark -> allow cycle). Separate from the
# security hook-canary above since this is a stateful 2-step check, not a single deny probe.
if [ -f "$hooks_dir/require-profile-lock-read.sh" ] && [ -f "$project_root/.claude/PROFILE.lock.md" ]; then
  gate_fails=()
  canary_session="doctor-canary-$$-$RANDOM"
  r4="$(echo "{\"session_id\":\"$canary_session\",\"cwd\":\"$project_root\",\"tool_input\":{\"file_path\":\"foo.ts\"}}" | bash "$hooks_dir/require-profile-lock-read.sh" 2>/dev/null)"
  printf '%s' "$r4" | grep -q "deny" || gate_fails+=("require-profile-lock-read: did NOT deny before the lock was read")
  echo "{\"session_id\":\"$canary_session\",\"tool_input\":{\"file_path\":\"$project_root/.claude/PROFILE.lock.md\"}}" | bash "$hooks_dir/mark-profile-lock-read.sh" >/dev/null 2>&1
  r5="$(echo "{\"session_id\":\"$canary_session\",\"cwd\":\"$project_root\",\"tool_input\":{\"file_path\":\"foo.ts\"}}" | bash "$hooks_dir/require-profile-lock-read.sh" 2>/dev/null)"
  [ -z "$r5" ] || gate_fails+=("require-profile-lock-read: still denies AFTER the lock was marked read")
  rm -rf "$HOME/.claude/logs/session-state/$canary_session" 2>/dev/null
  if [ "${#gate_fails[@]}" -eq 0 ]; then
    add_check "profile-lock-gate" "OK" "deny -> mark -> allow cycle verified"
  else
    add_check "profile-lock-gate" "FAIL" "$(printf '%s; ' "${gate_fails[@]}")"
  fi
fi

# 3. Evals (opt-in, since it shells out to routing scripts per fixture - not free)
if [ "$run_evals" -eq 1 ]; then
  if command -v jq >/dev/null 2>&1; then
    eval_out="$(bash "$script_dir/run-evals.sh" --json 2>/dev/null)"
    eval_pass="$(printf '%s' "$eval_out" | jq -r '.pass // 0')"
    eval_total="$(printf '%s' "$eval_out" | jq -r '.total // 0')"
    eval_status="OK"; [ "${eval_pass:-0}" != "${eval_total:-0}" ] && eval_status="WARN"
    add_check "evals" "$eval_status" "pass=$eval_pass/$eval_total"
  else
    add_check "evals" "WARN" "jq not found - skipped"
  fi
fi

# 4. Safe auto-repair (idempotent, never overwrites existing custom content).
if [ "$fix_safe" -eq 1 ]; then
  fixed=()
  if [ "$struct_ok" -eq 0 ]; then
    bash "$script_dir/init-claude-project.sh" "$project_root" --skip-existing-claude-md >/dev/null 2>&1 || true
    fixed+=("re-ran init (restored missing OS files, preserved existing)")
  fi
  lock_path="$project_root/.claude/PROFILE.lock.md"
  if [ ! -f "$lock_path" ]; then
    bash "$script_dir/gen-profile-lock.sh" "$project_root" >/dev/null 2>&1 || true
    fixed+=("generated missing PROFILE.lock")
  fi
  if [ "${#fixed[@]}" -gt 0 ]; then
    fixed_joined="$(printf '%s; ' "${fixed[@]}")"
    add_check "fix-safe" "OK" "$fixed_joined"
    # Re-verify after repair so Overall reflects POST-fix state, not the pre-fix snapshot.
    recheck_out="$(bash "$script_dir/check-claude-md-os.sh" "$project_root" 2>&1)"
    recheck_ok=0; printf '%s' "$recheck_out" | grep -q "All required files present" && recheck_ok=1
    for i in "${!check_names[@]}"; do
      if [ "${check_names[$i]}" = "structure" ]; then
        if [ "$recheck_ok" -eq 1 ]; then
          check_status[$i]="OK"; check_detail[$i]="all files present (post-fix)"
        else
          check_status[$i]="FAIL"; check_detail[$i]="still missing files after fix-safe"
        fi
      fi
    done
  else
    add_check "fix-safe" "OK" "nothing to fix"
  fi
fi

overall="OK"
for s in "${check_status[@]}"; do
  [ "$s" = "FAIL" ] && overall="FAIL" && break
done
if [ "$overall" != "FAIL" ]; then
  for s in "${check_status[@]}"; do
    [ "$s" = "WARN" ] && overall="WARN" && break
  done
fi

if [ "$json" -eq 1 ]; then
  if ! command -v jq >/dev/null 2>&1; then echo "jq not found - install jq for --json output" >&2; exit 1; fi
  checks_json="$(for i in "${!check_names[@]}"; do
    jq -nc --arg name "${check_names[$i]}" --arg status "${check_status[$i]}" --arg detail "${check_detail[$i]}" \
      '{name: $name, status: $status, detail: $detail}'
  done | jq -sc '.')"
  jq -nc --arg overall "$overall" --argjson checks "$checks_json" '{overall: $overall, checks: $checks}'
  [ "$overall" = "FAIL" ] && exit 1
  exit 0
fi

echo "SREDNOFF OS doctor"
for i in "${!check_names[@]}"; do
  echo "  [${check_status[$i]}] ${check_names[$i]}: ${check_detail[$i]}"
done
echo "Overall: $overall"
[ "$overall" = "FAIL" ] && exit 1
exit 0
