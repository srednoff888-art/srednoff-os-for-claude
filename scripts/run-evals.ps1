#requires -Version 5.1
<#
.SYNOPSIS
  SREDNOFF OS eval runner. Regression-tests the domain router and selector against fixed
  briefs so a routing/tag change can't silently break skill selection. Ported concept from
  srednoff-os (Codex sibling): evals/*.json + doctor -RunEvals.
.EXAMPLE
  .\run-evals.ps1
  .\run-evals.ps1 -Json
#>
param([switch]$Json)
$ErrorActionPreference = "Stop"

$Registry = Join-Path $env:USERPROFILE ".claude\registry"
$ModeRouter = Join-Path $Registry "mode-router.ps1"
$DomainRouter = Join-Path $Registry "domain-router.ps1"
$Selector = Join-Path $Registry "select-skills.ps1"
$ModeFixtures = Join-Path $Registry "evals\mode-fixtures.json"
$DomainFixtures = Join-Path $Registry "evals\domain-fixtures.json"
$SelectorFixtures = Join-Path $Registry "evals\selector-fixtures.json"
$SecretFixtures = Join-Path $Registry "evals\secret-pattern-fixtures.json"
$HookLib = Join-Path $env:USERPROFILE ".claude\templates\claude-md-os\.claude\hooks\hook-lib.ps1"

$results = New-Object System.Collections.Generic.List[object]

# Secret-pattern regression (real gitleaks/vendor fixtures, not invented examples - closes
# a gap found in critical review: patterns were never validated against an independent
# corpus, only against test strings the same author who wrote the regex also wrote).
if ((Test-Path -LiteralPath $SecretFixtures) -and (Test-Path -LiteralPath $HookLib)) {
  . $HookLib
  $fixtures = Get-Content -LiteralPath $SecretFixtures -Raw | ConvertFrom-Json
  foreach ($f in $fixtures) {
    $hits = Find-SecretSignals -Text $f.text
    $got = $hits.Count -gt 0
    $pass = ($got -eq $f.expectMatch)
    $results.Add([pscustomobject]@{ suite = "secret-pattern"; id = $f.id; pass = $pass; expected = "match=$($f.expectMatch)"; got = "match=$got ($($hits -join ','))" }) | Out-Null
  }
}

if (Test-Path -LiteralPath $ModeFixtures) {
  $fixtures = Get-Content -LiteralPath $ModeFixtures -Raw | ConvertFrom-Json
  foreach ($f in $fixtures) {
    $out = & powershell -NoProfile -ExecutionPolicy Bypass -File $ModeRouter -Brief $f.brief -Json 2>$null | ConvertFrom-Json
    $pass = ($out.mode -eq $f.expectedMode)
    $results.Add([pscustomobject]@{ suite = "mode"; id = $f.id; pass = $pass; expected = $f.expectedMode; got = $out.mode }) | Out-Null
  }
}

if (Test-Path -LiteralPath $DomainFixtures) {
  $fixtures = Get-Content -LiteralPath $DomainFixtures -Raw | ConvertFrom-Json
  foreach ($f in $fixtures) {
    $out = & powershell -NoProfile -ExecutionPolicy Bypass -File $DomainRouter -Brief $f.brief -Json 2>$null | ConvertFrom-Json
    $got = @($out.domains)
    $pass = $false
    foreach ($exp in $f.expectedDomains) { if ($got -contains $exp) { $pass = $true; break } }
    $results.Add([pscustomobject]@{ suite = "domain"; id = $f.id; pass = $pass; expected = ($f.expectedDomains -join ","); got = ($got -join ",") }) | Out-Null
  }
}

if (Test-Path -LiteralPath $SelectorFixtures) {
  $fixtures = Get-Content -LiteralPath $SelectorFixtures -Raw | ConvertFrom-Json
  foreach ($f in $fixtures) {
    $out = & powershell -NoProfile -ExecutionPolicy Bypass -File $Selector -Brief $f.brief -Budget $f.budget -Json -NoLog 2>$null | ConvertFrom-Json
    $gotNames = @($out.picked | ForEach-Object { $_.name })
    $pass = $false
    foreach ($exp in $f.expectedAny) { if ($gotNames -contains $exp) { $pass = $true; break } }
    $results.Add([pscustomobject]@{ suite = "selector"; id = $f.id; pass = $pass; expected = ($f.expectedAny -join ","); got = ($gotNames -join ",") }) | Out-Null
  }
}

# Quota invariant: "lean" budget must never surface a G3 (heavyweight) record - that's the
# whole point of lean. This guards the budget-quota math itself, not just name matching.
$leanOut = & powershell -NoProfile -ExecutionPolicy Bypass -File $Selector -Brief "add Stripe checkout to the Next.js app" -Budget lean -Max 12 -Json -NoLog 2>$null | ConvertFrom-Json
$leanG3Count = @($leanOut.picked | Where-Object { $_.group -eq 3 }).Count
$results.Add([pscustomobject]@{ suite = "invariant"; id = "lean_budget_no_g3"; pass = ($leanG3Count -eq 0); expected = "0 G3 records"; got = "$leanG3Count G3 records" }) | Out-Null

$passCount = @($results | Where-Object pass).Count
$total = $results.Count

if ($Json) {
  [ordered]@{ pass = $passCount; total = $total; results = $results } | ConvertTo-Json -Depth 8
  exit 0
}

foreach ($r in $results) {
  $mark = if ($r.pass) { "OK  " } else { "FAIL" }
  Write-Output ("[$mark] $($r.suite)/$($r.id)  expected one of: $($r.expected)")
  if (-not $r.pass) { Write-Output ("        got: $($r.got)") }
}
Write-Output ""
Write-Output ("SREDNOFF OS evals: $passCount/$total passed")
if ($passCount -lt $total) { exit 1 }
exit 0
