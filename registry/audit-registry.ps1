#requires -Version 5.1
<#
.SYNOPSIS
  SREDNOFF OS registry audit: catches data-quality debt in CORE-300.md that no other
  script checks - duplicate skill names (confuses the selector/canon), and a count of
  external (non-INST/ANTH) records that are due for a staleness re-check.
.DESCRIPTION
  Closes 2 real gaps: (1) known duplicate entries across the 4 additions were never
  structurally caught before; (2) external GH/WSH/VOLT/FTB/EXT links can go stale
  (renamed/deleted/relicensed) and nothing was tracking how many exist or when to recheck.
  This does NOT hit the network (no per-URL liveness check - that would be slow/costly for
  ~150 links); it is the cheap, always-safe first line of defense. A full liveness check
  is a deliberate P2 (out of scope here - would need ~150 GitHub API calls).
.EXAMPLE
  .\audit-registry.ps1
  .\audit-registry.ps1 -Json
#>
param([switch]$Json)
$ErrorActionPreference = "Stop"

$core = Join-Path $PSScriptRoot "CORE-300.md"
if (-not (Test-Path -LiteralPath $core)) { Write-Error "CORE-300.md not found: $core"; exit 1 }
. "$PSScriptRoot\routing-lib.ps1"

$catalog = Get-CoreCatalog -CorePath $core

# Duplicate names (case-insensitive) - same skill name appearing under 2+ numbers means
# either an accidental re-add across "addition" (Dopolnenie) sections, or a real overlap that should
# have one canonical entry (see CAPABILITY-INDEX.md).
$dupGroups = $catalog | Group-Object { $_.name.ToLowerInvariant() } | Where-Object { $_.Count -gt 1 }
$duplicates = @($dupGroups | ForEach-Object {
  [pscustomobject]@{ name = $_.Name; count = $_.Count; nums = @($_.Group | ForEach-Object { $_.num }) }
})

# External-source count by tag (rough proxy via source-code letters in the raw line text).
# BUG FIXES (found via cross-platform debug review, 2026-07-01), both make PowerShell match
# audit-registry.sh's already-correct behavior:
# (1) 'EXT\b' only anchored the RIGHT edge, so it matched inside "Next.js", "context", "text",
#     "extension" etc. Fixed with a two-sided boundary (no non-letter before OR after "EXT").
# (2) PowerShell's -match is case-INSENSITIVE by default; bash's awk/grep are case-sensitive.
#     Source tags (WSH/VOLT/FTB/GH:/EXT) are meant as exact-case markers, not natural-language
#     words - case-insensitive matching let lowercase substrings inside real skill NAMES
#     (e.g. `voltagent:create-voltagent`, `wshuyi:x-article-publisher-skill`) false-positive
#     as if they were VOLT/WSH-sourced records. Fixed with -cmatch (case-sensitive) throughout.
$externalPattern = 'GH:|WSH|VOLT|FTB|(?<![A-Za-z])EXT(?![A-Za-z])'
$externalRecords = @($catalog | Where-Object { $_.line -cmatch $externalPattern })
$instRecords = @($catalog | Where-Object { $_.line -cmatch '\bINST\b|\bANTH\b|ANTH-OFF' })

$result = [ordered]@{
  name                  = "SREDNOFF OS registry audit"
  total_records         = $catalog.Count
  duplicate_names       = $duplicates
  duplicate_count       = $duplicates.Count
  external_records      = $externalRecords.Count
  installed_records     = $instRecords.Count
  external_recheck_due  = "quarterly (see CHANGELOG.md policy) - next due ~2026-09-28"
}

if ($Json) {
  $result | ConvertTo-Json -Depth 8
  exit ($(if ($duplicates.Count -gt 0) { 1 } else { 0 }))
}

Write-Output ("SREDNOFF OS registry audit: {0} records ({1} installed, {2} external)" -f $result.total_records, $result.installed_records, $result.external_records)
if ($duplicates.Count -eq 0) {
  Write-Output "  duplicates: none"
} else {
  Write-Output ("  duplicates: {0}" -f $duplicates.Count)
  foreach ($d in $duplicates) { Write-Output ("    '{0}' appears at #{1}" -f $d.name, ($d.nums -join ', #')) }
}
Write-Output ("  external staleness recheck: {0}" -f $result.external_recheck_due)
if ($duplicates.Count -gt 0) { exit 1 }
exit 0
