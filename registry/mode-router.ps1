#requires -Version 5.1
<#
.SYNOPSIS
  SREDNOFF OS mode router. Classifies a task brief into normal/deep/turbo and reports the
  matching budget + max shortlist size. Ported concept from srednoff-os (Codex sibling).
.DESCRIPTION
  TURBO fires ONLY on the literal word "turbo" (case-insensitive). Synonyms like
  "maximally", "dont skimp on tokens", "production", "security audit" etc. trigger "deep",
  never "turbo" - matches Principle #1: quality first, but no silent uncontrolled scope growth.
.EXAMPLE
  .\mode-router.ps1 -Brief "TURBO fix the checkout bug"
  .\mode-router.ps1 -Brief "sdelay maksimalno kachestvenno arhitekturu" -Json
#>
param(
  [string]$Brief = "",
  [switch]$Json
)
$ErrorActionPreference = "Stop"
. "$PSScriptRoot\routing-lib.ps1"

$result = Get-Mode -Brief $Brief
$result.name = "SREDNOFF OS mode router"

if ($Json) {
  $result | ConvertTo-Json -Depth 6
} else {
  Write-Output ("SREDNOFF OS mode: {0} | budget={1} | max={2} | reason={3}" -f $result.mode, $result.budget, $result.max_capabilities, $result.reason)
}
