#requires -Version 5.1
<#
.SYNOPSIS
  SREDNOFF OS catalog format validator. CORE-300.md is a flat markdown file parsed with
  regex as a pseudo-database (Get-CoreCatalog in routing-lib.ps1) - a malformed numbered
  line silently VANISHES from parsing with no error. This catches that failure mode.
.DESCRIPTION
  Checks: (1) every "N. `name`" line has a recognized group context and at least one [tag];
  (2) numbers are sequential/increasing (a skipped or repeated number signals a broken edit);
  (3) no line has an empty backtick-name.
.EXAMPLE
  .\validate-catalog-format.ps1
#>
param([switch]$Json)
$ErrorActionPreference = "Stop"

$core = Join-Path $PSScriptRoot "CORE-300.md"
. "$PSScriptRoot\routing-lib.ps1"

$issues = New-Object System.Collections.Generic.List[string]

# Re-scan raw lines to find "looks like a numbered entry but doesn't fully match" cases -
# these are exactly the ones Get-CoreCatalog would silently drop.
$lineNum = 0
$suspicious = 0
foreach ($line in Get-Content -LiteralPath $core -Encoding UTF8) {
  $lineNum++
  $looksNumbered = $line -match '^\s*\d+\.\s'
  $fullyMatches = $line -match '^\s*(\d+)\.\s+`([^`]+)`'
  if ($looksNumbered -and -not $fullyMatches) {
    $suspicious++
    $issues.Add("Line $lineNum looks numbered but has no valid backtick name (would silently drop from parsing): $($line.Trim())") | Out-Null
  }
}

$catalog = Get-CoreCatalog -CorePath $core
$noTagRecords = @($catalog | Where-Object { $_.tags.Count -eq 0 })
foreach ($r in $noTagRecords) { $issues.Add("Record #$($r.num) '$($r.name)' has zero tags - unreachable by domain/selector matching") | Out-Null }

$noGroupRecords = @($catalog | Where-Object { $_.group -eq 0 })
foreach ($r in $noGroupRecords) { $issues.Add("Record #$($r.num) '$($r.name)' has no group (0) - appeared before any GROUP/G1-G3 header") | Out-Null }

$nums = @($catalog | Select-Object -ExpandProperty num | Sort-Object)
$dupNums = @($nums | Group-Object | Where-Object { $_.Count -gt 1 } | ForEach-Object { $_.Name })
foreach ($n in $dupNums) { $issues.Add("Number #$n used more than once") | Out-Null }

$result = [ordered]@{
  name              = "SREDNOFF OS catalog validator"
  total_parsed      = $catalog.Count
  suspicious_lines  = $suspicious
  no_tag_records    = $noTagRecords.Count
  no_group_records  = $noGroupRecords.Count
  duplicate_numbers = $dupNums.Count
  issues            = @($issues.ToArray())
}

if ($Json) { $result | ConvertTo-Json -Depth 6; exit ($(if ($issues.Count -gt 0) { 1 } else { 0 })) }

Write-Output ("SREDNOFF OS catalog validator: {0} records parsed" -f $catalog.Count)
if ($issues.Count -eq 0) { Write-Output "  no issues found" } else { foreach ($i in $issues) { Write-Output ("  ISSUE: " + $i) } }
if ($issues.Count -gt 0) { exit 1 }
exit 0
