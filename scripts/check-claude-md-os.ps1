#requires -Version 5.1
<#
.SYNOPSIS
  Check whether a project has the required Claude MD OS files (Windows / PowerShell).
.PARAMETER ProjectPath
  Target project directory. Defaults to current directory.
#>
[CmdletBinding()]
param(
  [Parameter(Position = 0)]
  [string]$ProjectPath = "."
)

$ErrorActionPreference = "Stop"
$Target = (Resolve-Path -LiteralPath $ProjectPath).Path

$required = @(
  "CLAUDE.md",
  "AGENTS.md",
  "code_review.md",
  ".claude\rules\00-operating-system.md",
  ".claude\rules\10-github-research.md",
  ".claude\rules\20-connectors.md",
  ".claude\rules\30-user-briefing.md",
  ".claude\rules\40-quality-gate.md",
  ".claude\rules\50-security.md",
  ".claude\rules\60-exec-plans.md",
  ".claude\rules\70-skills-registry.md",
  ".claude\rules\80-model-routing.md",
  ".claude\rules\90-subagent-contract.md",
  ".claude\skills\github-research\SKILL.md",
  ".claude\skills\product-builder\SKILL.md",
  ".claude\skills\production-review\SKILL.md",
  ".claude\skills\connector-orchestrator\SKILL.md",
  ".claude\skills\project-bootstrap\SKILL.md",
  ".agent\PLANS.md",
  ".agent\TASK_TEMPLATE.md",
  ".agent\GITHUB_RESEARCH.md",
  ".agent\CONNECTORS.md",
  ".agent\QUALITY_GATE.md",
  ".agent\USER_BRIEFING.md"
)

Write-Host "Claude MD OS check: $Target" -ForegroundColor Cyan
$missing = @()
foreach ($r in $required) {
  $p = Join-Path $Target $r
  if (Test-Path -LiteralPath $p) {
    Write-Host "  OK    $r" -ForegroundColor Green
  } else {
    Write-Host "  MISS  $r" -ForegroundColor Red
    $missing += $r
  }
}

Write-Host ""
if ($missing.Count -eq 0) {
  Write-Host "All required files present." -ForegroundColor Green
  exit 0
} else {
  Write-Host "Missing $($missing.Count) file(s). Fix with:" -ForegroundColor Yellow
  Write-Host "  & `"`$env:USERPROFILE\.claude\templates\claude-md-os\scripts\init-claude-project.ps1`" ."
  exit 1
}
