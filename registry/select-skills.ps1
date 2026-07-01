#requires -Version 5.1
<#
.SYNOPSIS
  SREDNOFF OS quality/cost selector. Picks a shortlist from CORE-300.md by relevance to a
  task brief and by budget-shaped group quotas, WITHOUT loading the whole catalog into
  context. Ported concept from srednoff-os (Codex sibling: select_core_capabilities.py).
.DESCRIPTION
  Principle #1 still governs: quality first, economy only at equal quality. This selector
  therefore only fills a group quota with records that are actually tag-relevant - it never
  pads the shortlist with irrelevant filler just to hit a number.
.EXAMPLE
  .\select-skills.ps1 -Brief "add Stripe checkout to the Next.js app" -Budget balanced -Max 16
  .\select-skills.ps1 -Brief "TURBO full security audit before launch" -Json
#>
param(
  [string]$Brief = "",
  [string]$Budget = "",
  [int]$Max = 0,
  [string]$Tags = "",
  [switch]$Json,
  [switch]$NoLog
)
$ErrorActionPreference = "Stop"
. "$PSScriptRoot\routing-lib.ps1"

$core = Join-Path $PSScriptRoot "CORE-300.md"
if (-not (Test-Path -LiteralPath $core)) { Write-Error "CORE-300.md not found: $core"; exit 1 }

$modeInfo = Get-Mode -Brief $Brief
if (-not $Budget) { $Budget = $modeInfo.budget }
if ($Max -le 0) { $Max = $modeInfo.max_capabilities }

$domainTags = if ($Tags) { @($Tags -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ }) } else { Get-DomainTags -Brief $Brief }

$catalog = Get-CoreCatalog -CorePath $core

# Relevance = count of tags that overlap with the requested domain (meta does NOT count
# toward relevance - it's a fallback so universal skills stay reachable, but a specific
# match must always outrank a generic [meta] entry. Fixes a real bug: sorting by catalog
# number alone let low-numbered [meta] records crowd out on-topic picks (Principle #1).
# PERFORMANCE (2000+ records): plain for-loop + HashSet + List<T>, no pipeline/Add-Member -
# Add-Member in a 2000-iteration pipeline was the dominant cost (measured 3-5s), far more
# than the catalog load itself. This construct is the standard PowerShell fast-path.
$domainSet = New-Object System.Collections.Generic.HashSet[string]
foreach ($t in $domainTags) { [void]$domainSet.Add($t) }
$matchedList = New-Object System.Collections.Generic.List[object]
foreach ($rec in $catalog) {
  $specificCount = 0
  $isMeta = $false
  foreach ($t in $rec.tags) {
    if ($t -eq "meta") { $isMeta = $true }
    elseif ($domainSet.Contains($t)) { $specificCount++ }
  }
  if ($specificCount -gt 0 -or $isMeta) {
    $matchedList.Add([pscustomobject]@{ num = $rec.num; name = $rec.name; group = $rec.group; tags = $rec.tags; relevance = $specificCount }) | Out-Null
  }
}
$matched = $matchedList

$quota = $BudgetQuotas[$Budget]
if (-not $quota) { $quota = $BudgetQuotas["balanced"] }

$picked = New-Object System.Collections.Generic.List[object]
foreach ($g in 1, 2, 3) {
  $groupQuota = [Math]::Ceiling($Max * $quota[$g])
  if ($groupQuota -le 0) { continue }
  $groupMatches = @($matched | Where-Object { $_.group -eq $g } |
    Sort-Object -Property @{Expression = "relevance"; Descending = $true }, @{Expression = "num"; Descending = $false } |
    Select-Object -First $groupQuota)
  foreach ($m in $groupMatches) { $picked.Add($m) | Out-Null }
}
$picked = @($picked | Select-Object -First $Max)

# Usage log (on by default, opt out with -NoLog). Closes the "we never track catalog usage"
# gap: doctor/audit-registry can later mine this to find dead entries. Not the security
# hook ledger (different file, different purpose/audience) - plain text is fine here since
# a task brief on a personal machine isn't secret, unlike hook-scanned tool input.
if (-not $NoLog) {
  try {
    $logDir = Join-Path $env:USERPROFILE ".claude\logs"
    New-Item -ItemType Directory -Force -Path $logDir -ErrorAction SilentlyContinue | Out-Null
    $logPath = Join-Path $logDir "selector-usage.jsonl"
    $briefSnippet = if ($Brief.Length -gt 100) { $Brief.Substring(0, 100) + "..." } else { $Brief }
    $usageEntry = [ordered]@{
      ts          = (Get-Date).ToUniversalTime().ToString("o")
      brief       = $briefSnippet
      domain_tags = $domainTags
      budget      = $Budget
      mode        = $modeInfo.mode
      picked      = @($picked | ForEach-Object { $_.name })
    }
    $usageLine = ($usageEntry | ConvertTo-Json -Compress -Depth 6) + [Environment]::NewLine
    $usageEnc = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::AppendAllText($logPath, $usageLine, $usageEnc)
  } catch {}
}

$resultObj = [ordered]@{
  name           = "SREDNOFF OS selector"
  brief          = $Brief
  domain_tags    = $domainTags
  budget         = $Budget
  max            = $Max
  mode           = $modeInfo.mode
  matched_total  = $matched.Count
  picked_total   = $picked.Count
  picked         = @($picked | ForEach-Object { [ordered]@{ num = $_.num; name = $_.name; group = $_.group; tags = $_.tags } })
}

if ($Json) {
  $resultObj | ConvertTo-Json -Depth 8
} else {
  Write-Output ("SREDNOFF OS selector: mode={0} budget={1} tags={2} matched={3} picked={4}" -f $modeInfo.mode, $Budget, ($domainTags -join ','), $resultObj.matched_total, $resultObj.picked_total)
  foreach ($p in $picked) { Write-Output ("  G{0} {1} [{2}]" -f $p.group, $p.name, ($p.tags -join ',')) }
  if ($picked.Count -eq 0) { Write-Output "  (no relevant matches - broaden the brief or pass -Tags explicitly)" }
}
