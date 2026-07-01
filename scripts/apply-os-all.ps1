#requires -Version 5.1
<#
.SYNOPSIS
  Apply Claude MD OS to EVERY project subfolder under a root that is missing it.
  Belt-and-suspenders for "apply to all projects" without a SessionStart hook.
.PARAMETER Root
  Workspace root (default: C:\my-workspace).
.EXAMPLE
  .\apply-os-all.ps1
  .\apply-os-all.ps1 "C:\my-workspace"
#>
[CmdletBinding()]
param([Parameter(Position = 0)][string]$Root = (Get-Location).Path)

$ErrorActionPreference = "Stop"
$init = Join-Path $PSScriptRoot "init-claude-project.ps1"
if (-not (Test-Path $init)) { Write-Error "init script not found: $init"; exit 1 }

$applied = 0; $skipped = 0
Get-ChildItem $Root -Directory -Force -ErrorAction SilentlyContinue | ForEach-Object {
  $dir = $_.FullName
  if ($_.Name -eq ".claude") { return }   # skip workspace aux folder
  $hasOS = Test-Path (Join-Path $dir ".claude\rules\00-operating-system.md")
  $looksProject = (Test-Path (Join-Path $dir "package.json")) -or
                  (Test-Path (Join-Path $dir ".git")) -or
                  (Get-ChildItem $dir -Filter *.md -ErrorAction SilentlyContinue | Select-Object -First 1)
  if ($hasOS) { Write-Host ("= {0} (already has OS)" -f $_.Name) -ForegroundColor DarkGray; $skipped++; return }
  if (-not $looksProject) { Write-Host ("- {0} (not a project, skipped)" -f $_.Name) -ForegroundColor DarkGray; return }
  Write-Host ("+ {0} -> applying OS" -f $_.Name) -ForegroundColor Green
  & $init $dir -SkipExistingClaudeMd *> $null
  $applied++
}
Write-Host ""
Write-Host ("Done. Applied: {0} | Already had OS: {1}" -f $applied, $skipped) -ForegroundColor Cyan
