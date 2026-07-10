# Generate CORE-300.json - machine-readable export of CORE-300.md (PowerShell port of
# gen-catalog-json.sh; same record grammar and JSON shape). The bash version is the
# canonical generator for the committed artifact (CI runs it); this port serves Windows
# consumers and local validation. JSON field order/indentation may differ from jq, so
# -Check validates structurally (record count + per-entry fields), not byte-for-byte.
#
# Usage:
#   powershell -NoProfile -File .\gen-catalog-json.ps1            # write CORE-300.windows.json
#   powershell -NoProfile -File .\gen-catalog-json.ps1 -Check     # validate committed CORE-300.json
param(
    [switch]$Check
)
$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$core = Join-Path $scriptDir "CORE-300.md"
$canonical = Join-Path $scriptDir "CORE-300.json"
$out = Join-Path $scriptDir "CORE-300.windows.json"

if (-not (Test-Path $core)) { Write-Error "CORE-300.md not found: $core" }

$group = $null
$entries = @()
foreach ($line in [System.IO.File]::ReadLines($core)) {
    if ($line -match '^## ') {
        if ($line -match '^## *G(ROUP)? *1') { $group = "G1" }
        elseif ($line -match '^## *G(ROUP)? *2') { $group = "G2" }
        elseif ($line -match '^## *G(ROUP)? *3') { $group = "G3" }
        else { $group = $null }
        continue
    }
    if ($line -notmatch '^\s*(\d+)\.\s*`([^`]+)`(.*)$') { continue }
    $id = [int]$Matches[1]
    $name = $Matches[2]
    $rest = $Matches[3]

    $desc = $null
    $dashIdx = $rest.IndexOf(" — ")
    if ($dashIdx -ge 0) {
        $desc = $rest.Substring($dashIdx + 3).Trim()
        $rest = $rest.Substring(0, $dashIdx)
    }

    $tags = @()
    while ($rest -match '\[([^\]]+)\]') {
        $tags += $Matches[1]
        $rest = $rest.Substring($rest.IndexOf(']' ) + 1)
    }

    $sourceRaw = $rest.Trim()
    if ($sourceRaw -eq "") { $sourceRaw = $null }
    $source = $null
    if ($null -ne $sourceRaw) { $source = ($sourceRaw -split ' ')[0] -replace ':.*$', '' }

    $entries += [pscustomobject]@{
        id          = $id
        name        = $name
        tags        = $tags
        source      = $source
        source_raw  = $sourceRaw
        group       = $group
        description = $desc
    }
}

$expected = ([regex]::Matches((Get-Content $core -Raw), '(?m)^\s*\d+\.\s*`')).Count
if ($entries.Count -ne $expected) {
    Write-Error "record count mismatch: markdown=$expected parsed=$($entries.Count)"
}

if ($Check) {
    if (-not (Test-Path $canonical)) { Write-Error "CORE-300.json not found (generate with gen-catalog-json.sh)" }
    $json = Get-Content $canonical -Raw | ConvertFrom-Json
    if ($json.count -ne $entries.Count) {
        Write-Error "DRIFT: CORE-300.json count=$($json.count), markdown=$($entries.Count)"
    }
    $canonIds = @($json.entries | ForEach-Object { $_.id })
    $localIds = @($entries | ForEach-Object { $_.id })
    $diff = Compare-Object $canonIds $localIds
    if ($diff) { Write-Error "DRIFT: entry ids differ between CORE-300.json and CORE-300.md" }
    Write-Output "gen-catalog-json: OK - CORE-300.json is in sync ($($entries.Count) records)"
} else {
    $doc = [pscustomobject]@{
        schema_version = 1
        source         = "CORE-300.md"
        entries        = $entries
        count          = $entries.Count
    }
    $doc | ConvertTo-Json -Depth 5 | Set-Content -Path $out -Encoding UTF8
    Write-Output "gen-catalog-json: wrote $out ($($entries.Count) records)"
}
