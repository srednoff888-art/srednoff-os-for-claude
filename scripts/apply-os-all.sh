#!/usr/bin/env bash
# Apply SREDNOFF OS to EVERY project subfolder under a root that is missing it
# (Linux/macOS port of apply-os-all.ps1). Belt-and-suspenders for "apply to all projects"
# without a SessionStart hook.
#
# Usage:
#   ./apply-os-all.sh                  # root = current directory
#   ./apply-os-all.sh /path/to/workspace
set -uo pipefail
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
init="$script_dir/init-claude-project.sh"
root="${1:-$(pwd)}"

if [ ! -f "$init" ]; then echo "init script not found: $init" >&2; exit 1; fi

applied=0; skipped=0
for dir in "$root"/*/; do
  [ -d "$dir" ] || continue
  dir="${dir%/}"
  name="$(basename "$dir")"
  [ "$name" = ".claude" ] && continue

  has_os=0
  [ -f "$dir/.claude/rules/00-operating-system.md" ] && has_os=1
  looks_project=0
  if [ -f "$dir/package.json" ] || [ -d "$dir/.git" ] || find "$dir" -maxdepth 1 -name "*.md" -print -quit 2>/dev/null | grep -q .; then
    looks_project=1
  fi

  if [ "$has_os" -eq 1 ]; then
    echo "= $name (already has OS)"
    skipped=$((skipped + 1))
    continue
  fi
  if [ "$looks_project" -eq 0 ]; then
    echo "- $name (not a project, skipped)"
    continue
  fi
  echo "+ $name -> applying OS"
  bash "$init" "$dir" --skip-existing-claude-md >/dev/null 2>&1 || true
  applied=$((applied + 1))
done

echo ""
echo "Done. Applied: $applied | Already had OS: $skipped"
