#requires -Version 5.1
<#
.SYNOPSIS
  SREDNOFF OS doctor: one command for status + structural check + evals + safe auto-repair.
  Ported concept from srednoff-os (Codex sibling): srednoff-os-doctor.ps1 -RunEvals -FixSafe.
.EXAMPLE
  .\doctor.ps1 -ProjectPath "C:\my-workspace\my-nextjs-app" -RunEvals -FixSafe
#>
param(
  [string]$ProjectPath = ".",
  [switch]$Json,
  [switch]$RunEvals,
  [switch]$FixSafe
)
$ErrorActionPreference = "Stop"

$ScriptDir = $PSScriptRoot
$Registry = Join-Path $env:USERPROFILE ".claude\registry"
$ProjectRoot = if (Test-Path -LiteralPath $ProjectPath) { (Resolve-Path -LiteralPath $ProjectPath).Path } else { $ProjectPath }

$Checks = New-Object System.Collections.Generic.List[object]
function Add-Check {
  param([string]$Name, [ValidateSet("OK", "WARN", "FAIL")][string]$Status, [string]$Detail)
  $script:Checks.Add([pscustomobject]@{ name = $Name; status = $Status; detail = $Detail }) | Out-Null
}

# 1. Status one-liner
$statusOut = & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $ScriptDir "status.ps1") -ProjectPath $ProjectRoot
Add-Check -Name "status" -Status ($(if ($statusOut -match "loaded: OK") { "OK" } else { "WARN" })) -Detail $statusOut

# 2. Structural file check (existing check-claude-md-os.ps1)
$structOut = & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $ScriptDir "check-claude-md-os.ps1") $ProjectRoot 2>&1 | Out-String
$structOk = $structOut -match "All required files present"
Add-Check -Name "structure" -Status ($(if ($structOk) { "OK" } else { "FAIL" })) -Detail ($(if ($structOk) { "all files present" } else { ($structOut -split "`n" | Where-Object { $_ -match "MISS" }) -join "; " }))

# 2b. Registry audit (cheap, local-only, no network - always safe to run)
$auditOut = & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $Registry "audit-registry.ps1") -Json 2>$null | ConvertFrom-Json
Add-Check -Name "registry-audit" -Status ($(if ($auditOut.duplicate_count -eq 0) { "OK" } else { "WARN" })) -Detail "records=$($auditOut.total_records); duplicates=$($auditOut.duplicate_count)"

# 2c. Catalog format validation (catches malformed lines that would silently vanish from parsing)
$validateOut = & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $Registry "validate-catalog-format.ps1") -Json 2>$null | ConvertFrom-Json
$validateOk = $validateOut.issues.Count -eq 0
Add-Check -Name "catalog-format" -Status ($(if ($validateOk) { "OK" } else { "WARN" })) -Detail "parsed=$($validateOut.total_parsed); issues=$($validateOut.issues.Count)"

# 2d. Registry/template version control (closes: "no rollback point for the 2000+ record
# catalog"). Auto-commits any pending changes so a bad edit is always revertible via git,
# WITHOUT relying on remembering to commit by hand - the same class of failure as a prose
# rule getting skipped. Cheap (local git only, no push, no network).
function Invoke-AutoCommit {
  param([string]$RepoPath, [string]$Label)
  if (-not (Test-Path -LiteralPath (Join-Path $RepoPath ".git"))) { return "no-repo" }
  # Native git writing to stderr (even benign LF/CRLF warnings) becomes a terminating error
  # under $ErrorActionPreference = "Stop" in PS 5.1, regardless of 2>$null redirection.
  # Scope EAP down to Continue just for these native calls, then restore it.
  $prevEap = $ErrorActionPreference
  $ErrorActionPreference = "Continue"
  Push-Location $RepoPath
  try {
    $dirty = git status --porcelain 2>$null
    if ([string]::IsNullOrWhiteSpace($dirty)) { return "clean" }
    git add -A 2>$null 1>$null
    $ts = (Get-Date).ToUniversalTime().ToString("o")
    git -c user.email="srednoff-os@local" -c user.name="Srednoff OS doctor" commit -q -m "doctor auto-commit ($Label): $ts" 2>$null 1>$null
    return "committed"
  } finally {
    Pop-Location
    $ErrorActionPreference = $prevEap
  }
}
$registryGit = Invoke-AutoCommit -RepoPath $Registry -Label "registry"
$templateGit = Invoke-AutoCommit -RepoPath (Join-Path $env:USERPROFILE ".claude\templates\claude-md-os") -Label "template"
Add-Check -Name "version-control" -Status "OK" -Detail "registry=$registryGit; template=$templateGit"

# 2e. Hook canary test (closes: "fail-open hooks break silently with zero visibility").
# Feeds each hook a KNOWN-bad synthetic input and confirms it still denies/blocks. If a
# hook has regressed (bug swallowed by its own try/catch), this makes it visible in doctor
# instead of silently passing everything through at runtime.
$hooksDir = Join-Path $ProjectRoot ".claude\hooks"
if (Test-Path -LiteralPath (Join-Path $hooksDir "block-dangerous-bash.ps1")) {
  $canaryFails = @()
  $r1 = '{"tool_input":{"command":"mkfs.ext4 /dev/sda1"}}' | & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $hooksDir "block-dangerous-bash.ps1")
  if ($r1 -notmatch "deny") { $canaryFails += "block-dangerous-bash: known-dangerous command was NOT denied" }
  $r2 = '{"tool_input":{"file_path":"app/.env"}}' | & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $hooksDir "protect-secrets.ps1")
  if ($r2 -notmatch "deny") { $canaryFails += "protect-secrets: known-secret path was NOT denied" }
  $r3 = '{"prompt":"sk-ant-api03-abcdefghijklmnopqrstuvwx"}' | & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $hooksDir "scan-prompt-secrets.ps1")
  if ($r3 -notmatch '"decision":"block"') { $canaryFails += "scan-prompt-secrets: known-secret prompt was NOT blocked" }
  Add-Check -Name "hook-canary" -Status ($(if ($canaryFails.Count -eq 0) { "OK" } else { "FAIL" })) -Detail ($(if ($canaryFails.Count -eq 0) { "3/3 canary triggers still deny/block as expected" } else { $canaryFails -join "; " }))
}

# 2f. PROFILE.lock enforcement gate canary (deny -> mark -> allow cycle). Separate from the
# security hook-canary above since this is a stateful 2-step check, not a single deny probe.
if ((Test-Path -LiteralPath (Join-Path $hooksDir "require-profile-lock-read.ps1")) -and (Test-Path -LiteralPath (Join-Path $ProjectRoot ".claude\PROFILE.lock.md"))) {
  $gateFails = @()
  $canarySession = "doctor-canary-$([guid]::NewGuid().ToString('N'))"
  $cwdJson = ($ProjectRoot -replace '\\', '\\')
  $r4 = "{`"session_id`":`"$canarySession`",`"cwd`":`"$cwdJson`",`"tool_input`":{`"file_path`":`"foo.ts`"}}" | & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $hooksDir "require-profile-lock-read.ps1")
  if ($r4 -notmatch "deny") { $gateFails += "require-profile-lock-read: did NOT deny before the lock was read" }
  $lockJson = "$cwdJson\\.claude\\PROFILE.lock.md"
  "{`"session_id`":`"$canarySession`",`"tool_input`":{`"file_path`":`"$lockJson`"}}" | & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $hooksDir "mark-profile-lock-read.ps1") | Out-Null
  $r5 = "{`"session_id`":`"$canarySession`",`"cwd`":`"$cwdJson`",`"tool_input`":{`"file_path`":`"foo.ts`"}}" | & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $hooksDir "require-profile-lock-read.ps1")
  if ($r5) { $gateFails += "require-profile-lock-read: still denies AFTER the lock was marked read" }
  Remove-Item -Recurse -Force -ErrorAction SilentlyContinue (Join-Path $env:USERPROFILE ".claude\logs\session-state\$canarySession")
  Add-Check -Name "profile-lock-gate" -Status ($(if ($gateFails.Count -eq 0) { "OK" } else { "FAIL" })) -Detail ($(if ($gateFails.Count -eq 0) { "deny -> mark -> allow cycle verified" } else { $gateFails -join "; " }))
}

# 3. Evals (opt-in, since it shells out to routing scripts per fixture - not free)
if ($RunEvals) {
  $evalOut = & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $ScriptDir "run-evals.ps1") -Json 2>$null | ConvertFrom-Json
  $evalOk = $evalOut.pass -eq $evalOut.total
  Add-Check -Name "evals" -Status ($(if ($evalOk) { "OK" } else { "WARN" })) -Detail "pass=$($evalOut.pass)/$($evalOut.total)"
}

# 4. Safe auto-repair (idempotent, never overwrites existing custom content - same
# guarantee as init-claude-project.ps1 has always had: backup-on-diff, skip-on-identical).
if ($FixSafe) {
  $fixed = @()
  if (-not $structOk) {
    & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $ScriptDir "init-claude-project.ps1") $ProjectRoot -SkipExistingClaudeMd *> $null
    $fixed += "re-ran init (restored missing OS files, preserved existing)"
  }
  $lockPath = Join-Path $ProjectRoot ".claude\PROFILE.lock.md"
  if (-not (Test-Path -LiteralPath $lockPath)) {
    & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $ScriptDir "gen-profile-lock.ps1") $ProjectRoot *> $null
    $fixed += "generated missing PROFILE.lock"
  }
  if ($fixed.Count -gt 0) {
    Add-Check -Name "fix-safe" -Status "OK" -Detail ($fixed -join "; ")
    # Re-verify after repair so Overall reflects POST-fix state, not the pre-fix snapshot.
    $recheck = & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $ScriptDir "check-claude-md-os.ps1") $ProjectRoot 2>&1 | Out-String
    $recheckOk = $recheck -match "All required files present"
    $structIdx = 0
    for ($i = 0; $i -lt $Checks.Count; $i++) { if ($Checks[$i].name -eq "structure") { $structIdx = $i } }
    $Checks[$structIdx] = [pscustomobject]@{ name = "structure"; status = ($(if ($recheckOk) { "OK" } else { "FAIL" })); detail = ($(if ($recheckOk) { "all files present (post-fix)" } else { "still missing files after fix-safe" })) }
  } else {
    Add-Check -Name "fix-safe" -Status "OK" -Detail "nothing to fix"
  }
}

$overall = if (@($Checks | Where-Object { $_.status -eq "FAIL" }).Count -gt 0) { "FAIL" }
elseif (@($Checks | Where-Object { $_.status -eq "WARN" }).Count -gt 0) { "WARN" }
else { "OK" }

if ($Json) {
  [ordered]@{ overall = $overall; checks = $Checks } | ConvertTo-Json -Depth 8
  exit ($(if ($overall -eq "FAIL") { 1 } else { 0 }))
}

Write-Output "SREDNOFF OS doctor"
foreach ($c in $Checks) { Write-Output ("  [{0}] {1}: {2}" -f $c.status, $c.name, $c.detail) }
Write-Output ("Overall: {0}" -f $overall)
if ($overall -eq "FAIL") { exit 1 }
exit 0
