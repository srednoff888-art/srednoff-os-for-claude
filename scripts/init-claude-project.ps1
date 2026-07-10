#requires -Version 5.1
<#
.SYNOPSIS
  Initialize Claude MD OS files into a target project (Windows / PowerShell).
.DESCRIPTION
  Copies the Claude MD OS template package into the given project directory.
  - Never overwrites silently: existing files are backed up as <file>.bak.<timestamp>.
  - Never deletes anything.
  - Never creates an active .claude/settings.json (only settings.example.json is copied).
  - Reports created / updated(backed up) / skipped files.
.PARAMETER ProjectPath
  Target project directory. Defaults to current directory.
.PARAMETER SkipExistingClaudeMd
  If the project already has its own CLAUDE.md, leave it completely untouched
  (do not back up or replace). Use this when rolling the OS into existing projects
  that have a tailored CLAUDE.md you want to keep active.
.EXAMPLE
  .\init-claude-project.ps1 .
  .\init-claude-project.ps1 "C:\my-workspace\my-nextjs-app"
  .\init-claude-project.ps1 "C:\my-workspace\my-project" -SkipExistingClaudeMd
#>
[CmdletBinding()]
param(
  [Parameter(Position = 0)]
  [string]$ProjectPath = ".",
  [switch]$SkipExistingClaudeMd
)

$ErrorActionPreference = "Stop"

# Template root = parent of this scripts/ folder
$TemplateRoot = Split-Path -Parent $PSScriptRoot
$Target = (Resolve-Path -LiteralPath $ProjectPath).Path
$Stamp = Get-Date -Format "yyyyMMdd-HHmmss"

if (-not (Test-Path -LiteralPath $TemplateRoot)) {
  Write-Error "Template root not found: $TemplateRoot"
  exit 1
}

# Hard safety guard: never let target resolve to $HOME/$env:USERPROFILE itself. This
# tool deploys a full project structure (rules/hooks/skills/CLAUDE.md/etc.) - the user's
# profile root is a global config location, never a "project". Defense in depth, added
# after a real incident where init-claude-project.sh (which had extra git-root-walking
# logic this script never had) resolved a scratch path to $HOME and deployed there.
$HomeResolved = (Resolve-Path -LiteralPath $env:USERPROFILE).Path.TrimEnd('\')
if ($Target.TrimEnd('\') -ieq $HomeResolved) {
  Write-Error "init-claude-project: refusing to init directly into `$env:USERPROFILE ($HomeResolved) - this is not a project directory. Pass an explicit project path."
  exit 1
}

Write-Host "Claude MD OS init" -ForegroundColor Cyan
Write-Host "  Template: $TemplateRoot"
Write-Host "  Target:   $Target"
Write-Host ""

# Collect every file in the template except the scripts/ folder itself
# (scripts are tooling, not project content). settings.json is never created.
$created = @()
$updated = @()
$skipped = @()

$files = Get-ChildItem -LiteralPath $TemplateRoot -Recurse -File -Force | Where-Object {
  $rel = $_.FullName.Substring($TemplateRoot.Length).TrimStart('\','/')
  # Skip repo/distribution tooling that is NOT per-project content: the scripts folder
  # (installer tooling), the template's OWN git history (a real bug found while testing the
  # Linux port - without this every new project silently received the template's .git blobs),
  # the .github CI workflows, the .claude-plugin manifests and the plugin hooks/ wiring
  # (those describe how to DISTRIBUTE the OS as a Claude Code plugin, not what a project needs),
  # and any accidental settings.json.
  ($rel -notlike "scripts\*") -and ($rel -notlike ".git\*") -and ($rel -notlike ".github\*") -and
  ($rel -notlike ".claude-plugin\*") -and ($rel -notlike "hooks\*") -and ($rel -ne ".claude\settings.json")
}

$preserved = @()

foreach ($f in $files) {
  $rel = $f.FullName.Substring($TemplateRoot.Length).TrimStart('\','/')

  # Keep a project's own CLAUDE.md active if requested.
  if ($SkipExistingClaudeMd -and ($rel -eq "CLAUDE.md")) {
    $existingClaude = Join-Path $Target "CLAUDE.md"
    if (Test-Path -LiteralPath $existingClaude) {
      $preserved += $rel
      continue
    }
  }

  $dest = Join-Path $Target $rel
  $destDir = Split-Path -Parent $dest
  if (-not (Test-Path -LiteralPath $destDir)) {
    New-Item -ItemType Directory -Force -Path $destDir | Out-Null
  }

  if (Test-Path -LiteralPath $dest) {
    # Compare content; if identical, skip. Otherwise back up then copy.
    $same = $false
    try {
      $a = Get-FileHash -LiteralPath $dest -Algorithm SHA256
      $b = Get-FileHash -LiteralPath $f.FullName -Algorithm SHA256
      $same = ($a.Hash -eq $b.Hash)
    } catch { $same = $false }

    if ($same) {
      $skipped += $rel
      continue
    }

    $backup = "$dest.bak.$Stamp"
    Copy-Item -LiteralPath $dest -Destination $backup -Force
    Copy-Item -LiteralPath $f.FullName -Destination $dest -Force
    $updated += "$rel  (backup: $(Split-Path -Leaf $backup))"
  }
  else {
    Copy-Item -LiteralPath $f.FullName -Destination $dest -Force
    $created += $rel
  }
}

Write-Host "Created ($($created.Count)):" -ForegroundColor Green
$created | ForEach-Object { Write-Host "  + $_" }
Write-Host ""
Write-Host "Updated / backed up ($($updated.Count)):" -ForegroundColor Yellow
$updated | ForEach-Object { Write-Host "  ~ $_" }
Write-Host ""
Write-Host "Skipped (identical) ($($skipped.Count)):" -ForegroundColor DarkGray
$skipped | ForEach-Object { Write-Host "  = $_" }
Write-Host ""
if ($preserved.Count -gt 0) {
  Write-Host "Preserved (kept project's own, untouched) ($($preserved.Count)):" -ForegroundColor Magenta
  $preserved | ForEach-Object { Write-Host "  ! $_" }
  Write-Host ""
}
Write-Host "Done. Hooks are NOT active. To enable them:" -ForegroundColor Cyan
Write-Host "  Copy-Item .claude\settings.example.json .claude\settings.json"

# Generate PROFILE.lock (cached skill selection for the stack), if the registry is available.
$genLock = Join-Path $PSScriptRoot "gen-profile-lock.ps1"
$coreReg = Join-Path $env:USERPROFILE ".claude\registry\CORE-300.md"
if ((Test-Path $genLock) -and (Test-Path $coreReg)) {
  Write-Host ""
  & $genLock $Target
}
