#requires -Version 5.1
<#
.SYNOPSIS
  Initialize Claude MD OS files into a target project (Windows / PowerShell).
.DESCRIPTION
  Copies the Claude MD OS template package into the given project directory.
  - Only ever ships the OS's project-bootstrap surface (CLAUDE.md, code_review.md, AGENTS.md,
    .claude/rules|skills|commands|hooks, .claude/settings*.example.json, .agent/**). The OS
    repo's own about-itself files (README*, LICENSE, .gitignore, QUALITY.md, RELEASE.md,
    docs/**, benchmarks/**, registry/**, skills-library/**) are NEVER copied into a target
    project - registry/skills-library are meant to be consumed via the global registry
    symlink/install, not duplicated per project.
  - CREATE-ONLY: creates the files the project is missing and never changes one that already
    exists. An existing file that differs from the template is left untouched and listed in
    the report - whether or not it is committed, whether or not the project is a git repo.
    A .bak file is not consent, and this script also runs in the background (global
    SessionStart hook, doctor -FixSafe, apply-os-all -Sync). Pass -Force to replace the files
    that differ (each is backed up to <file>.bak.<stamp> first). Only a human at a prompt
    should.
  - Never deletes anything.
  - Never creates an active .claude/settings.json (only settings.example.json is copied).
  - Reports created / updated(backed up, -Force only) / skipped / kept(differs) files.
.PARAMETER ProjectPath
  Target project directory. Defaults to current directory.
.PARAMETER SkipExistingClaudeMd
  Kept for compatibility: create-only already leaves an existing CLAUDE.md alone. Unlike
  plain create-only it also wins over -Force for CLAUDE.md.
.PARAMETER Force
  Replace existing files that differ from the template instead of keeping them (backs them
  up first). Opt-in only; no automated path passes it.
.EXAMPLE
  .\init-claude-project.ps1 .
  .\init-claude-project.ps1 "C:\my-workspace\my-nextjs-app"
  .\init-claude-project.ps1 "C:\my-workspace\my-project" -SkipExistingClaudeMd
#>
[CmdletBinding()]
param(
  [Parameter(Position = 0)]
  [string]$ProjectPath = ".",
  [switch]$SkipExistingClaudeMd,
  [switch]$Force
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

# Collect only the template files in the project-bootstrap allow-list. Everything else in
# the template (README*, LICENSE, .gitignore, QUALITY.md, RELEASE.md, docs/, benchmarks/,
# registry/, skills-library/, scripts/, .git/, .github/, .claude-plugin/, top-level hooks/,
# .claude/settings.json) is the OS repo's own tooling/about-itself content and is never
# copied into a target project - registry/skills-library are consumed via the global
# registry install, not duplicated per project.
$created = @()
$updated = @()
$skipped = @()

$files = Get-ChildItem -LiteralPath $TemplateRoot -Recurse -File -Force | Where-Object {
  $rel = $_.FullName.Substring($TemplateRoot.Length).TrimStart('\','/')
  ($rel -eq "CLAUDE.md") -or ($rel -eq "code_review.md") -or ($rel -eq "AGENTS.md") -or
  ($rel -like ".claude\rules\*") -or ($rel -like ".claude\skills\*") -or
  ($rel -like ".claude\commands\*") -or ($rel -like ".claude\hooks\*") -or
  ($rel -eq ".claude\settings.example.json") -or ($rel -eq ".claude\settings.windows.example.json") -or
  ($rel -like ".agent\*")
}

$preserved = @()
$kept = @()

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
    # Compare content; identical -> skip. Different -> create-only keeps the project's file
    # and reports it; only -Force backs it up and replaces it.
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

    if (-not $Force) {
      $kept += $rel
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
if ($kept.Count -gt 0) {
  Write-Host "Kept (differs from template, not modified - pass -Force to replace) ($($kept.Count)):" -ForegroundColor Magenta
  $kept | ForEach-Object { Write-Host "  ! $_" }
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
