#requires -Version 5.1
<#
.SYNOPSIS
  Generate .claude/PROFILE.lock.md - a cached skill-selection for the project,
  so the agent does not have to grep CORE-300.md (482 lines) every session.
.DESCRIPTION
  Heuristically classifies the project (manifests/name), picks dominant domain
  tags, and pulls candidate entries from the global CORE-300.md by those tags.
  This is a STARTING set - the agent refines per task (Principle #1: quality first).
  ASCII-only on purpose: Windows PowerShell 5.1 misparses non-ASCII .ps1 without BOM.
.PARAMETER ProjectPath
  Project folder (default: current).
#>
[CmdletBinding()]
param([Parameter(Position = 0)][string]$ProjectPath = ".")

$ErrorActionPreference = "Stop"
$Target = (Resolve-Path -LiteralPath $ProjectPath).Path
$name = Split-Path -Leaf $Target
$core = Join-Path $env:USERPROFILE ".claude\registry\CORE-300.md"
if (-not (Test-Path -LiteralPath $core)) { Write-Error "CORE-300.md not found: $core"; exit 1 }
$total = (Select-String -Path $core -Pattern '^\s*\d+\.').Count

$tags = [System.Collections.Generic.List[string]]::new()
function Add-Tag($t) { if (-not $tags.Contains($t)) { $tags.Add($t) } }

# --- heuristic classification ---
if (Test-Path "$Target\package.json") {
  Add-Tag "web"; Add-Tag "frontend"
  $pkg = Get-Content "$Target\package.json" -Raw -ErrorAction SilentlyContinue
  if ($pkg -match '"three"|@react-three') { Add-Tag "3d"; Add-Tag "animation" }
  if ($pkg -match 'framer-motion|gsap') { Add-Tag "animation" }
  if ($pkg -match '@anthropic|openai|ai-sdk') { Add-Tag "ai" }
  if ($pkg -match 'tailwind|shadcn') { Add-Tag "design" }
}
if ((Test-Path "$Target\requirements.txt") -or (Test-Path "$Target\pyproject.toml")) {
  Add-Tag "backend"
  $py = ((Get-Content "$Target\requirements.txt" -Raw -ErrorAction SilentlyContinue), (Get-Content "$Target\pyproject.toml" -Raw -ErrorAction SilentlyContinue)) -join " "
  if ($py -match 'ccxt|backtest|binance|trading') { Add-Tag "trading" }
  if ($py -match 'torch|sklearn|scikit|tensorflow|pandas|numpy') { Add-Tag "ml"; Add-Tag "data" }
}
if (Get-ChildItem -LiteralPath $Target -Filter *.ps1 -ErrorAction SilentlyContinue | Select-Object -First 1) { Add-Tag "windows" }
if ((Test-Path "$Target\Dockerfile") -or (Get-ChildItem -LiteralPath $Target -Filter *.tf -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1)) { Add-Tag "infra"; Add-Tag "devops" }
if ($name -match 'amazon|fba|huntlandia') { Add-Tag "amazon"; Add-Tag "business"; Add-Tag "marketing" }
if ($name -match 'seo') { Add-Tag "seo" }
if ($name -match 'freelance|outreach|strategy|sales|crm') { Add-Tag "sales"; Add-Tag "marketing" }
if ($name -match 'design') { Add-Tag "design" }
if ($tags.Count -eq 0) { Add-Tag "web" }

# --- pull candidates from CORE-300 by tags ---
$pattern = ($tags | ForEach-Object { "\[$_\]" }) -join "|"
# dedupe by skill name (first backticked token) so G2/G3 variants of the same capability collapse
$seen = New-Object System.Collections.Generic.HashSet[string]
$cand = Select-String -Path $core -Pattern $pattern |
  Where-Object { $_.Line -match '^\s*\d+\.' } |
  ForEach-Object { $_.Line.Trim() } |
  Where-Object {
    $key = if ($_ -match '`([^`]+)`') { $matches[1] } else { $_ }
    $seen.Add($key)
  } | Select-Object -First 40

# --- write lock (ASCII body) ---
$lockDir = Join-Path $Target ".claude"
New-Item -ItemType Directory -Force -Path $lockDir | Out-Null
$lock = Join-Path $lockDir "PROFILE.lock.md"
$ts = Get-Date -Format "yyyy-MM-dd HH:mm"

$body = New-Object System.Collections.Generic.List[string]
$body.Add("# PROFILE.lock - cached skill selection for project '$name'")
$body.Add("")
$body.Add("Generated $ts by gen-profile-lock.ps1. CACHE: load this instead of grepping CORE-300.md ($total entries) each session = context saving.")
$body.Add("Principle #1: QUALITY FIRST, economy only at equal quality. Starting set - refine per task; any CORE-300 entry may be called.")
$body.Add("Model routing: see 80-model-routing.md (G1~Haiku, G2~Sonnet, G3~Opus by required quality).")
$body.Add("External agents (GH/WSH/VOLT/FTB/EXT) = unvetted until github-research + license check (see 70-skills-registry.md).")
$body.Add("")
$body.Add("## Dominant tags")
$body.Add('`' + ($tags -join ', ') + '`')
$body.Add("")
$body.Add("## Candidates by tag (from CORE-300, up to 40). G1 generous | G2 targeted 3-7 | G3 on demand")
$body.Add("")
if ($cand.Count -eq 0) { $body.Add("_(no matches - classify manually via SELECTION-PROTOCOL.md)_") }
foreach ($m in $cand) { $body.Add("- " + $m) }
$body.Add("")
$body.Add("Full catalog: ~/.claude/registry/CORE-300.md | protocol: SELECTION-PROTOCOL.md")

Set-Content -LiteralPath $lock -Value ($body -join "`r`n") -Encoding UTF8

# --- Embed a compact selection into CLAUDE.md (always-loaded) so the agent sees the picks
# without needing a separate read of PROFILE.lock. Idempotent via markers. ASCII-only block. ---
$claudeMd = Join-Path $Target "CLAUDE.md"
if (Test-Path -LiteralPath $claudeMd) {
  # Prefer immediately-usable INST/ANTH skills first, then fill with the rest.
  $names = @()
  foreach ($pref in @($true, $false)) {
    foreach ($line in $cand) {
      $isInst = ($line -match ' INST') -or ($line -match ' ANTH')
      if ($pref -ne $isInst) { continue }
      if ($line -match '`([^`]+)`') { $nm = $matches[1]; if ($names -notcontains $nm) { $names += $nm } }
      if ($names.Count -ge 8) { break }
    }
    if ($names.Count -ge 8) { break }
  }
  $sel = ($names -join ", ")
  $tagStr = ($tags -join ", ")
  $m0 = "<!-- SREDNOFF-OS:SELECTION -->"
  $m1 = "<!-- /SREDNOFF-OS:SELECTION -->"
  $block = "$m0`r`n> **SREDNOFF OS - skills for this project** (full list: .claude/PROFILE.lock.md - read it first) | tags: $tagStr | top: $sel`r`n$m1"
  $enc2 = New-Object System.Text.UTF8Encoding($false)
  $md = [System.IO.File]::ReadAllText($claudeMd)
  $i0 = $md.IndexOf($m0); $i1 = $md.IndexOf($m1)
  if ($i0 -ge 0 -and $i1 -gt $i0) {
    $md = $md.Substring(0, $i0) + $block + $md.Substring($i1 + $m1.Length)
  } else {
    $nl = $md.IndexOf("`n")
    if ($nl -ge 0) { $md = $md.Substring(0, $nl + 1) + "`r`n" + $block + "`r`n" + $md.Substring($nl + 1) }
    else { $md = $block + "`r`n`r`n" + $md }
  }
  [System.IO.File]::WriteAllText($claudeMd, $md, $enc2)
}

Write-Host "PROFILE.lock: $lock" -ForegroundColor Green
Write-Host ("  tags: {0} | candidates: {1}" -f ($tags -join ','), $cand.Count)
