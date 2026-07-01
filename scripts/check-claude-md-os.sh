#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
target="${1:-.}"
target="$(cd "$target" && pwd)"

. "$script_dir/rule-file-list.sh"
required=(
  "CLAUDE.md"
  "AGENTS.md"
  "code_review.md"
)
for r in "${RULE_FILE_NAMES[@]}"; do
  required+=(".claude/rules/$r.md")
done
required+=(
  ".claude/skills/github-research/SKILL.md"
  ".claude/skills/product-builder/SKILL.md"
  ".claude/skills/production-review/SKILL.md"
  ".claude/skills/connector-orchestrator/SKILL.md"
  ".claude/skills/project-bootstrap/SKILL.md"
  ".agent/PLANS.md"
  ".agent/TASK_TEMPLATE.md"
  ".agent/GITHUB_RESEARCH.md"
  ".agent/CONNECTORS.md"
  ".agent/QUALITY_GATE.md"
  ".agent/USER_BRIEFING.md"
)

echo "Claude MD OS check: $target"
missing=0
for r in "${required[@]}"; do
  if [ -e "$target/$r" ]; then
    echo "  OK    $r"
  else
    echo "  MISS  $r"
    missing=$((missing+1))
  fi
done

echo ""
if [ "$missing" -eq 0 ]; then
  echo "All required files present."
  exit 0
else
  echo "Missing $missing file(s). Fix with:"
  echo "  ~/.claude/templates/claude-md-os/scripts/init-claude-project.sh ."
  exit 1
fi
