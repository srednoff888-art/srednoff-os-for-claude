#!/usr/bin/env bash
set -euo pipefail

target="${1:-.}"
target="$(cd "$target" && pwd)"

required=(
  "CLAUDE.md"
  "AGENTS.md"
  "code_review.md"
  ".claude/rules/00-operating-system.md"
  ".claude/rules/10-github-research.md"
  ".claude/rules/20-connectors.md"
  ".claude/rules/30-user-briefing.md"
  ".claude/rules/40-quality-gate.md"
  ".claude/rules/50-security.md"
  ".claude/rules/60-exec-plans.md"
  ".claude/rules/70-skills-registry.md"
  ".claude/rules/80-model-routing.md"
  ".claude/rules/90-subagent-contract.md"
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
