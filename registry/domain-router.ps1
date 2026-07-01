#requires -Version 5.1
<#
.SYNOPSIS
  SREDNOFF OS domain router. Classifies a TASK BRIEF (not just the project's static stack)
  into domains, then reports clarifying questions, canonical skill picks, and validation
  gates. Ported concept from srednoff-os (Codex sibling: srednoff-os-domain-router.ps1).
.DESCRIPTION
  Complements .claude/PROFILE.lock.md (generated once at init, per PROJECT). This router is
  dynamic and per-TASK: a web project can still get a 3D-domain answer if the brief is about
  a 3D configurator. Call it before substantial work when the task might span a new domain.
.EXAMPLE
  .\domain-router.ps1 -Brief "make a 3D product configurator with React Three Fiber" -Json
  .\domain-router.ps1 -ProjectPath "C:\my-workspace\my-nextjs-app" -Brief "SEO audit before launch"
#>
param(
  [string]$ProjectPath = ".",
  [string]$Brief = "",
  [switch]$Json
)
$ErrorActionPreference = "Stop"
. "$PSScriptRoot\routing-lib.ps1"

$modeInfo = Get-Mode -Brief $Brief
$domainTags = Get-DomainTags -Brief $Brief

# Only ask a clarifying brief for domains where the answer materially changes the product
# (matches Principle #1 / rule 30-user-briefing: ask only blocking, high-value questions).
$Questions = New-Object System.Collections.Generic.List[string]
if ($domainTags -contains "design" -or $domainTags -contains "frontend") {
  $Questions.Add("Target user, product/site type, and desired visual impression?") | Out-Null
}
if ($domainTags -contains "3d") {
  $Questions.Add("Is this a product viewer, hero scene, configurator, or decorative scene? What is the performance budget (mobile fallback needed)?") | Out-Null
}
if ($domainTags -contains "seo") {
  $Questions.Add("Full technical audit or a targeted fix (which pages/keywords)?") | Out-Null
}
if ($domainTags -contains "amazon") {
  $Questions.Add("Public data/research only, or does this touch the real Seller Central account (money/inventory)?") | Out-Null
}

$ValidationGates = New-Object System.Collections.Generic.List[string]
$ValidationGates.Add("lint-typecheck-build-tests") | Out-Null
$ValidationGates.Add("code-review") | Out-Null
if ($domainTags -contains "design" -or $domainTags -contains "frontend") { $ValidationGates.Add("accessibility") | Out-Null; $ValidationGates.Add("responsive-screenshots") | Out-Null }
if ($domainTags -contains "3d") { $ValidationGates.Add("canvas-nonblank") | Out-Null; $ValidationGates.Add("mobile-3d-fallback") | Out-Null; $ValidationGates.Add("asset-size-report") | Out-Null }
if ($domainTags -contains "security" -or $domainTags -contains "amazon" -or $domainTags -contains "trading") { $ValidationGates.Add("security-review") | Out-Null }
if ($domainTags -contains "seo") { $ValidationGates.Add("search-policy-review") | Out-Null }

$ConnectorSuggestions = New-Object System.Collections.Generic.List[string]
if ($domainTags -contains "design" -or $domainTags -contains "3d") { $ConnectorSuggestions.Add("figma") | Out-Null; $ConnectorSuggestions.Add("magic:21st.dev") | Out-Null }
if ($domainTags -contains "seo") { $ConnectorSuggestions.Add("dataforseo") | Out-Null }
if ($domainTags -contains "amazon") { $ConnectorSuggestions.Add("merchant_amazon_*") | Out-Null }

# Canonical near-free skill picks (G1+G2 only - G3 stays "on demand", per Principle #1).
# BUG FIX (found via debug review, 2026-07-01): this used to swallow a missing/broken
# CORE-300.md silently (empty skill_picks looked identical to "no relevant matches"). Now
# surfaces a distinct catalog_warning so a missing catalog is never confused with a normal
# no-match result.
$selector = Join-Path $PSScriptRoot "select-skills.ps1"
$coreCheck = Join-Path $PSScriptRoot "CORE-300.md"
$picks = @()
$catalogWarning = $null
if (-not (Test-Path -LiteralPath $coreCheck)) {
  $catalogWarning = "CORE-300.md not found at $coreCheck - skill_picks is empty because the catalog is missing, not because nothing matched."
} else {
  $picksJson = & $selector -Brief $Brief -Max 10 -Json 2>$null
  try { $picks = (@($picksJson | ConvertFrom-Json)[-1].picked | Where-Object { $_.group -le 2 }) }
  catch { $catalogWarning = "select-skills.ps1 did not return valid JSON - skill_picks is empty because the selector failed, not because nothing matched." }
}

$resultObj = [ordered]@{
  name                  = "SREDNOFF OS domain router"
  project               = $ProjectPath
  brief                 = $Brief
  domains               = $domainTags
  mode                  = $modeInfo.mode
  budget                = $modeInfo.budget
  questions             = @($Questions.ToArray())
  connector_suggestions = @($ConnectorSuggestions.ToArray())
  skill_picks           = @($picks | ForEach-Object { $_.name })
  catalog_warning       = $catalogWarning
  validation_gates      = @($ValidationGates.ToArray())
  external_source_rule  = "Any copy-adapt of external UI/3D/component code needs: license check, dependency-weight check, a11y/perf check, and provenance review (see CAPABILITY-INDEX.md + 70-skills-registry.md verification gate) before adoption."
}

if ($Json) {
  $resultObj | ConvertTo-Json -Depth 8
} else {
  Write-Output ("SREDNOFF OS domains: {0} | mode={1}/{2}" -f ($domainTags -join ','), $modeInfo.mode, $modeInfo.budget)
  if ($resultObj.questions.Count -gt 0) { Write-Output "Questions:"; $resultObj.questions | ForEach-Object { Write-Output ("  - " + $_) } }
  if ($catalogWarning) { Write-Output ("WARNING: " + $catalogWarning) }
  elseif ($resultObj.skill_picks.Count -gt 0) { Write-Output "Skill picks:"; $resultObj.skill_picks | ForEach-Object { Write-Output ("  - " + $_) } }
  Write-Output ("Validation gates: " + ($resultObj.validation_gates -join ', '))
}
