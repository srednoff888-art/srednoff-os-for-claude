#requires -Version 5.1
<#
.SYNOPSIS
  Apply Claude MD OS to EVERY project subfolder under a root that is missing it.
  Belt-and-suspenders for "apply to all projects" without a SessionStart hook.
  With -Sync, ALSO refreshes projects that already have the OS - re-runs init on
  them so rules/hooks/skills/scripts pick up template updates (concept ported from
  srednoff-os's sync-codex-skills-to-projects.ps1; implemented as a flag here instead
  of a parallel script, because init-claude-project.ps1 already does exactly what a
  sync needs - hash-diff, timestamped backup, CLAUDE.md preservation - re-running it
  on an initialized project IS the sync).
.PARAMETER Root
  Workspace root (default: G:\CLAUDE COWORK).
.PARAMETER Sync
  Also refresh already-initialized projects (re-run init, preserving each project's
  own CLAUDE.md). Without this switch, already-initialized projects are left untouched
  (original bootstrap-only behavior).
.EXAMPLE
  .\apply-os-all.ps1
  .\apply-os-all.ps1 "G:\CLAUDE COWORK" -Sync
#>
[CmdletBinding()]
param(
  [Parameter(Position = 0)][string]$Root = "G:\CLAUDE COWORK",
  [switch]$Sync
)

$ErrorActionPreference = "Stop"
$init = Join-Path $PSScriptRoot "init-claude-project.ps1"
if (-not (Test-Path $init)) { Write-Error "init script not found: $init"; exit 1 }

$applied = 0; $refreshed = 0; $skipped = 0
Get-ChildItem $Root -Directory -Force -ErrorAction SilentlyContinue | ForEach-Object {
  $dir = $_.FullName
  if ($_.Name -eq ".claude") { return }   # skip workspace aux folder
  $hasOS = Test-Path (Join-Path $dir ".claude\rules\00-operating-system.md")
  $looksProject = (Test-Path (Join-Path $dir "package.json")) -or
                  (Test-Path (Join-Path $dir ".git")) -or
                  (Get-ChildItem $dir -Filter *.md -ErrorAction SilentlyContinue | Select-Object -First 1)
  if ($hasOS) {
    if ($Sync) {
      Write-Host ("~ {0} -> syncing (refresh from template)" -f $_.Name) -ForegroundColor Yellow
      & $init $dir -SkipExistingClaudeMd *> $null
      $refreshed++
    } else {
      Write-Host ("= {0} (already has OS)" -f $_.Name) -ForegroundColor DarkGray
      $skipped++
    }
    return
  }
  if (-not $looksProject) { Write-Host ("- {0} (not a project, skipped)" -f $_.Name) -ForegroundColor DarkGray; return }
  Write-Host ("+ {0} -> applying OS" -f $_.Name) -ForegroundColor Green
  & $init $dir -SkipExistingClaudeMd *> $null
  $applied++
}
Write-Host ""
Write-Host ("Done. Applied: {0} | Refreshed: {1} | Already had OS (untouched): {2}" -f $applied, $refreshed, $skipped) -ForegroundColor Cyan
