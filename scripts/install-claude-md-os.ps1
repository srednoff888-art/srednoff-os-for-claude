#requires -Version 5.1
<#
.SYNOPSIS
  Install the Claude MD OS template package into ~/.claude/templates/claude-md-os
  and set up the global ~/.claude/CLAUDE.md bootstrap + code_review.md (Windows).
.DESCRIPTION
  Run this from the directory that contains the template package (the folder with
  CLAUDE.md, AGENTS.md, .claude/, .agent/, scripts/). If you are already running it
  from inside the installed template, it is idempotent.
  - Backs up an existing global ~/.claude/CLAUDE.md before changing it.
  - Appends the Bootstrap rule to the global CLAUDE.md if not already present
    (does NOT dump the full 700-line OS into the global file).
#>
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

$ClaudeHome = Join-Path $env:USERPROFILE ".claude"
$DestTemplate = Join-Path $ClaudeHome "templates\claude-md-os"
# Source = parent of this scripts/ folder
$Source = Split-Path -Parent $PSScriptRoot
$Stamp = Get-Date -Format "yyyyMMdd-HHmmss"

New-Item -ItemType Directory -Force -Path $DestTemplate | Out-Null

# Copy package into the global template location (skip if source == dest)
if ($Source -ne $DestTemplate) {
  Write-Host "Copying template -> $DestTemplate" -ForegroundColor Cyan
  Copy-Item -Path (Join-Path $Source '*') -Destination $DestTemplate -Recurse -Force
} else {
  Write-Host "Already running from the installed template location." -ForegroundColor DarkGray
}

# Global code_review.md
$globalReview = Join-Path $ClaudeHome "code_review.md"
Copy-Item -LiteralPath (Join-Path $DestTemplate "code_review.md") -Destination $globalReview -Force
Write-Host "Wrote $globalReview" -ForegroundColor Green

# Global CLAUDE.md: append the Bootstrap rule (back up first if it exists)
$globalClaude = Join-Path $ClaudeHome "CLAUDE.md"
$marker = "# Global Claude MD OS Bootstrap Rule"
$bootstrap = @"

$marker

At the start of work in any repository, check whether the project contains Claude MD OS files
(CLAUDE.md, code_review.md, .claude/rules/, .claude/skills/, .agent/).

If these files are missing and the repository is writable, initialize them from
``$env:USERPROFILE\.claude\templates\claude-md-os``.

If a file already exists, do not overwrite silently: preserve existing content, append only
missing Claude MD OS sections, or create a timestamped backup before replacing.

After initialization, continue the user's task.

If automatic file creation is unsafe or blocked, report the exact command the user can run:

``````powershell
& "`$env:USERPROFILE\.claude\templates\claude-md-os\scripts\init-claude-project.ps1" .
``````
"@

if (Test-Path -LiteralPath $globalClaude) {
  $existing = Get-Content -LiteralPath $globalClaude -Raw
  if ($existing -like "*$marker*") {
    Write-Host "Bootstrap rule already present in global CLAUDE.md - leaving as is." -ForegroundColor DarkGray
  } else {
    Copy-Item -LiteralPath $globalClaude -Destination "$globalClaude.bak.$Stamp" -Force
    Add-Content -LiteralPath $globalClaude -Value $bootstrap -Encoding UTF8
    Write-Host "Appended Bootstrap rule to existing global CLAUDE.md (backup made)." -ForegroundColor Yellow
  }
} else {
  Set-Content -LiteralPath $globalClaude -Value $bootstrap.TrimStart() -Encoding UTF8
  Write-Host "Created global CLAUDE.md with Bootstrap rule." -ForegroundColor Green
}

Write-Host ""
Write-Host "Install complete." -ForegroundColor Cyan
Write-Host "Add Claude MD OS to a project:"
Write-Host "  & `"`$env:USERPROFILE\.claude\templates\claude-md-os\scripts\init-claude-project.ps1`" /path/to/project"
