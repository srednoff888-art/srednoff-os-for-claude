#requires -Version 5.1
<#
.SYNOPSIS
  SREDNOFF OS status one-liner. Single source of truth instead of ad-hoc verification
  commands typed fresh each session. Ported concept from srednoff-os (Codex sibling).
.EXAMPLE
  .\status.ps1 -ProjectPath "C:\my-workspace\my-nextjs-app"
  .\status.ps1 -ProjectPath "." -Json
#>
param(
  [string]$ProjectPath = ".",
  [switch]$Json
)
$ErrorActionPreference = "Stop"

$ClaudeHome = Join-Path $env:USERPROFILE ".claude"
$Registry = Join-Path $ClaudeHome "registry"
$VersionFile = Join-Path $Registry "version.json"
$CoreCatalog = Join-Path $Registry "CORE-300.md"
$GlobalSettings = Join-Path $ClaudeHome "settings.json"
$ProjectRoot = if (Test-Path -LiteralPath $ProjectPath) { (Resolve-Path -LiteralPath $ProjectPath).Path } else { $ProjectPath }

function Count-CoreRecords {
  param([string]$Path)
  if (-not (Test-Path -LiteralPath $Path)) { return 0 }
  return (Select-String -Path $Path -Pattern '^\s*\d+\.\s+`').Count
}

$Version = "unknown"
if (Test-Path -LiteralPath $VersionFile) {
  try { $Version = (Get-Content -LiteralPath $VersionFile -Raw | ConvertFrom-Json).version } catch {}
}

$KernelCount = Count-CoreRecords -Path $CoreCatalog

$HooksOk = $false
if (Test-Path -LiteralPath $GlobalSettings) {
  try {
    $cfg = Get-Content -LiteralPath $GlobalSettings -Raw | ConvertFrom-Json
    $HooksOk = [bool]$cfg.hooks.SessionStart -and [bool]$cfg.statusLine
  } catch {}
}

$ProjectClaudeMd = Join-Path $ProjectRoot "CLAUDE.md"
$ProjectBannerOk = (Test-Path -LiteralPath $ProjectClaudeMd) -and ((Get-Content -LiteralPath $ProjectClaudeMd -Raw -ErrorAction SilentlyContinue) -match "SREDNOFF OS")
$RuleFiles = @("00-operating-system", "10-github-research", "20-connectors", "30-user-briefing", "40-quality-gate", "50-security", "60-exec-plans", "70-skills-registry", "80-model-routing", "90-subagent-contract")
$RulesPresent = 0
foreach ($r in $RuleFiles) { if (Test-Path -LiteralPath (Join-Path $ProjectRoot ".claude\rules\$r.md")) { $RulesPresent++ } }
$LockOk = Test-Path -LiteralPath (Join-Path $ProjectRoot ".claude\PROFILE.lock.md")

$Checks = [ordered]@{
  GlobalHooks   = $HooksOk
  Registry      = (Test-Path -LiteralPath $CoreCatalog)
  ProjectBanner = $ProjectBannerOk
  ProjectRules  = ($RulesPresent -eq $RuleFiles.Count)
  ProjectLock   = $LockOk
}
$Failed = @($Checks.GetEnumerator() | Where-Object { -not $_.Value } | ForEach-Object { $_.Key })
$Status = if ($Failed.Count -eq 0) { "OK" } else { "WARN" }
$ProjectState = if ($ProjectBannerOk -and ($RulesPresent -eq $RuleFiles.Count)) { "OK" } else { "SYNC_NEEDED" }

$Result = [ordered]@{
  name            = "SREDNOFF OS"
  version         = $Version
  status          = $Status
  project         = $ProjectRoot
  project_state   = $ProjectState
  rules_present   = "$RulesPresent/$($RuleFiles.Count)"
  registry_records = $KernelCount
  lock_present    = $LockOk
  failed_checks   = $Failed
  checks          = $Checks
}

if ($Json) {
  $Result | ConvertTo-Json -Depth 6
  exit 0
}

$failedText = if ($Failed.Count -gt 0) { " | failed=" + ($Failed -join ",") } else { "" }
Write-Output ("SREDNOFF OS {0} loaded: {1} | project={2} | rules={3} | registry={4} | lock={5}{6}" -f $Version, $Status, $ProjectState, $Result.rules_present, $KernelCount, $LockOk, $failedText)
