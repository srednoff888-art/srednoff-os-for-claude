# Canonical list of the 10 numbered rule files under .claude/rules/. Dot-source this instead
# of hardcoding the list a second time (found via refactoring review, 2026-07-01:
# status.ps1 previously kept its own independent copy of this list, which would silently
# desync from check-claude-md-os.ps1's canonical copy if a new rule file were ever added).
$RuleFileNames = @(
  "00-operating-system",
  "10-github-research",
  "20-connectors",
  "30-user-briefing",
  "40-quality-gate",
  "50-security",
  "60-exec-plans",
  "70-skills-registry",
  "80-model-routing",
  "90-subagent-contract"
)
