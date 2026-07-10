# Shared routing helpers for SREDNOFF OS. Dot-source: . "$PSScriptRoot\routing-lib.ps1"
# Concepts ported from srednoff-os (Codex sibling project): domain-tag detection from a
# task brief, mode/budget classification (normal/deep/turbo), and a catalog parser.
# ASCII-only on purpose (PS 5.1 breaks on non-ASCII tokens in .ps1 without BOM - see memory).

$TagKeywords = @{
  "web"       = @('web app', 'website', 'landing', 'frontend app', 'browser')
  "frontend"  = @('frontend', '\bui\b', 'react\b', 'vue\b', 'angular\b', 'next\.?js', 'component')
  "backend"   = @('backend', '\bapi\b', 'server\b', 'fastapi', 'django', 'express', 'endpoint')
  "3d"        = @('\b3d\b', 'three\.?js', '\br3f\b', 'react three fiber', 'webgl', 'webgpu', 'gltf', 'glb', 'babylon', 'shader', 'configurator')
  "animation" = @('animation', 'motion\b', 'gsap', 'framer motion', 'scroll.?trigger', 'transition')
  "design"    = @('design system', 'ui kit', 'figma', 'shadcn', 'tailwind', 'visual design', 'brand\b')
  "seo"       = @('\bseo\b', 'sitemap', 'hreflang', 'schema\.org', '\bserp\b', 'crawl', 'indexing')
  "marketing" = @('marketing', 'campaign', 'email sequence', '\bads\b', '\bppc\b', 'growth\b')
  "sales"     = @('\bsales\b', 'outreach', '\blead\b', '\bcrm\b', 'prospect')
  "amazon"    = @('amazon\b', '\bfba\b', '\basin\b', 'seller central', 'sp-api')
  "trading"   = @('trading', 'backtest', 'exchange api', 'ccxt', 'portfolio', 'risk manager')
  "ml"        = @('machine learning', '\bml\b', 'model training', 'pytorch', 'tensorflow', '\bllm\b')
  "ai"        = @('\bai\b', 'openai', 'anthropic', 'claude', '\bgpt\b', '\brag\b', 'embedding')
  "data"      = @('database', '\bsql\b', 'postgres', 'data pipeline', '\betl\b', 'analytics')
  "infra"     = @('infrastructure', 'docker', 'kubernetes', 'terraform', 'cloud\b')
  "devops"    = @('devops', 'ci/?cd', 'deploy', 'pipeline', 'github actions')
  "security"  = @('security', '\bauth\b', 'oauth', 'vulnerability', 'penetration', 'secrets?\b')
  "test"      = @('\btest', 'testing', '\be2e\b', 'playwright', 'cypress', 'unit test')
  "mobile"    = @('mobile\b', '\bios\b', 'android\b', '\bexpo\b', 'react native', 'swiftui')
  "docs"      = @('documentation', 'readme', 'changelog', 'api docs')
  "legal"     = @('legal\b', 'contract\b', 'compliance', 'gdpr', 'privacy policy')
  "finance"   = @('finance\b', 'billing', 'invoice', 'accounting', 'pricing')
}

function Get-DomainTags {
  param([string]$Brief)
  $lower = $Brief.ToLowerInvariant()
  $tags = New-Object System.Collections.Generic.List[string]
  foreach ($tag in $TagKeywords.Keys) {
    foreach ($pattern in $TagKeywords[$tag]) {
      if ($lower -match $pattern) { $tags.Add($tag) | Out-Null; break }
    }
  }
  if ($tags.Count -eq 0) { $tags.Add("general") | Out-Null }
  return @($tags.ToArray() | Select-Object -Unique)
}

$TurboPatterns = @('(^|\s)turbo(\s|$)', '\bturbo\s+mode\b', '\bmode\s+turbo\b')
# Generic "go deep" synonyms with no specific domain signal - fall through to "production"
# (the lower of the two deep-tier quality modes) rather than "critical", which is reserved
# for the specific high-risk keywords in $CriticalPatterns below.
$DeepSynonymPatterns = @('maxim', 'do not skimp', "don't skimp", 'deep research', 'full audit')
# Russian deep-synonym-triggers via unicode escapes (avoids raw Cyrillic in a .ps1 file - see memory note).
$DeepSynonymPatternsRu = @(
  [string]::Concat([char]0x043C, [char]0x0430, [char]0x043A, [char]0x0441, [char]0x0438, [char]0x043C, [char]0x0430, [char]0x043B, [char]0x044C, [char]0x043D), # "maksimaln" (maximally)
  [string]::Concat([char]0x043D, [char]0x0435, [char]0x0020, [char]0x044D, [char]0x043A, [char]0x043E, [char]0x043D, [char]0x043E, [char]0x043C),                 # "ne ekonom" (don't skimp)
  [string]::Concat([char]0x0433, [char]0x043B, [char]0x0443, [char]0x0431, [char]0x043E, [char]0x043A, [char]0x0438, [char]0x0439)                                # "glubokiy" (deep)
)
# Quality modes (v1.15, ported concept from srednoff-os/Codex sibling, see registry/quality-modes.json):
# production = launch/deploy/release/SEO/PPC/growth/mobile/3D/architecture work.
$ProductionPatterns = @('production\b', '\blaunch\b', '\bdeploy(ment)?\b', '\brelease\b', '\bseo\b', '\bppc\b', 'growth\b', 'mobile\b', '\b3d\b', 'architecture')
# critical = high-risk security/auth/payments/data work - gets a bigger budget than production.
# NOTE: bare '\baudit\b' was deliberately dropped - it false-positived on "SEO audit" /
# "content audit" (caught by quality-mode-fixtures.json production_launch). 'security'/
# 'compliance' already cover the intended security/compliance-audit case without it.
# 'migrat' is scoped to database/schema/data migrations, not generic content migration.
$CriticalPatterns = @('security', '\bauth\b', 'oauth', 'payments?\b', '(database|db|schema|data)\b.{0,20}migrat', 'migrat.{0,20}(database|db|schema)\b', 'data loss', 'irreversible', 'compliance', 'crypto')

# Reads registry/quality-modes.json for validation_gates/group_policy per mode so those
# lists live in one place (the json), not duplicated in this function. Falls back to inline
# defaults if the file is missing/unreadable - non-security routing helper, fails open.
function Get-QualityModeMeta {
  param([string]$ModeName)
  $fallback = @{ validation_gates = @(); group_policy = "" }
  try {
    $jsonPath = Join-Path $PSScriptRoot "quality-modes.json"
    if (-not (Test-Path -LiteralPath $jsonPath)) { return $fallback }
    $doc = Get-Content -LiteralPath $jsonPath -Raw | ConvertFrom-Json
    $all = @($doc.modes) + @($doc.turbo_override)
    $match = $all | Where-Object { $_.name -eq $ModeName } | Select-Object -First 1
    if (-not $match) { return $fallback }
    return @{ validation_gates = @($match.validation_gates); group_policy = [string]$match.group_policy }
  } catch { return $fallback }
}

function Get-Mode {
  param([string]$Brief)
  $lower = $Brief.ToLowerInvariant()
  $isTurbo = $false
  foreach ($p in $TurboPatterns) { if ($lower -match $p) { $isTurbo = $true; break } }
  $isCritical = $false
  foreach ($p in $CriticalPatterns) { if ($lower -match $p) { $isCritical = $true; break } }
  $isProduction = $false
  if (-not $isCritical) {
    foreach ($p in $ProductionPatterns) { if ($lower -match $p) { $isProduction = $true; break } }
    if (-not $isProduction) {
      foreach ($p in $DeepSynonymPatterns) { if ($lower -match $p) { $isProduction = $true; break } }
    }
    if (-not $isProduction) {
      foreach ($p in $DeepSynonymPatternsRu) { if ($lower.Contains($p)) { $isProduction = $true; break } }
    }
  }
  $isFast = $false
  if (-not $isTurbo -and -not $isCritical -and -not $isProduction) {
    foreach ($p in @('\btypo\b', '\bsmall fix\b', '\bquick fix\b', '\bformat(ting)?\b', '\bquick check\b', '\bminor docs?\b')) {
      if ($lower -match $p) { $isFast = $true; break }
    }
  }

  $mode = if ($isTurbo) { "turbo" } elseif ($isCritical) { "critical" } elseif ($isProduction) { "production" } elseif ($isFast) { "fast" } else { "standard" }
  $legacyMode = if ($mode -eq "turbo") { "turbo" } elseif ($mode -in @("production", "critical")) { "deep" } else { "normal" }
  $budget = switch ($mode) { "turbo" { "turbo" } "fast" { "lean" } "production" { "deep" } "critical" { "deep" } default { "balanced" } }
  $maxCap = switch ($mode) { "turbo" { 48 } "fast" { 8 } "production" { 24 } "critical" { 32 } default { 16 } }
  $reason = switch ($mode) {
    "turbo"      { "explicit TURBO trigger" }
    "critical"   { "high-risk security/auth/payments/data trigger" }
    "production" { "launch/deploy/SEO/growth/production-facing trigger" }
    "fast"       { "small low-risk change trigger" }
    default      { "normal scoped work" }
  }
  $meta = Get-QualityModeMeta -ModeName $mode

  return [ordered]@{
    mode             = $mode
    legacy_mode      = $legacyMode
    budget           = $budget
    max_capabilities = $maxCap
    turbo            = $isTurbo
    reason           = $reason
    validation_gates = $meta.validation_gates
    group_policy     = $meta.group_policy
    safety           = [ordered]@{
      destructive_confirmation_required = $true
      paid_confirmation_required        = $true
      production_confirmation_required  = $true
    }
  }
}

# Budget quotas: share of the shortlist that should come from G1/G2/G3.
$BudgetQuotas = @{
  "lean"     = @{ 1 = 0.80; 2 = 0.20; 3 = 0.00 }
  "balanced" = @{ 1 = 0.50; 2 = 0.40; 3 = 0.10 }
  "deep"     = @{ 1 = 0.35; 2 = 0.45; 3 = 0.20 }
  "turbo"    = @{ 1 = 0.20; 2 = 0.45; 3 = 0.35 }
}

# Parses CORE-300.md into records: num, name, group(1/2/3), tags[], line text.
# PERFORMANCE (added after scaling the catalog to 2000+ records): re-parsing ~2000 lines of
# markdown with per-line regex on every single selector/router invocation measured ~4-5s of
# extra latency on top of PowerShell's own ~0.5-0.8s process-startup floor. Cached as JSON
# next to the source file; invalidated automatically whenever CORE-300.md's mtime changes,
# so the cache can never silently go stale after an edit.
function Get-CoreCatalog {
  param([string]$CorePath)

  $cachePath = Join-Path (Split-Path -Parent $CorePath) "core-catalog-index.json"
  $sourceTime = (Get-Item -LiteralPath $CorePath).LastWriteTimeUtc
  if (Test-Path -LiteralPath $cachePath) {
    $cacheTime = (Get-Item -LiteralPath $cachePath).LastWriteTimeUtc
    if ($cacheTime -ge $sourceTime) {
      try {
        $cached = Get-Content -LiteralPath $cachePath -Raw -Encoding UTF8 | ConvertFrom-Json
        $out = New-Object System.Collections.Generic.List[object]
        foreach ($c in $cached) {
          $out.Add([pscustomobject]@{ num = [int]$c.num; name = [string]$c.name; group = [int]$c.group; tags = @($c.tags); line = [string]$c.line }) | Out-Null
        }
        return $out
      } catch { }  # fall through to re-parse if the cache is somehow corrupt
    }
  }

  $records = New-Object System.Collections.Generic.List[object]
  $group = 0
  foreach ($line in Get-Content -LiteralPath $CorePath -Encoding UTF8) {
    if ($line -match '^#+\s*(GROUP\s*1\b|G1\b)') { $group = 1; continue }
    if ($line -match '^#+\s*(GROUP\s*2\b|G2\b)') { $group = 2; continue }
    if ($line -match '^#+\s*(GROUP\s*3\b|G3\b)') { $group = 3; continue }
    if ($line -match '^\s*(\d+)\.\s+`([^`]+)`(.*)$') {
      $num = [int]$Matches[1]; $name = $Matches[2]; $rest = $Matches[3]
      $tagMatches = [regex]::Matches($rest, '\[([a-zA-Z0-9]+)\]')
      $tags = @($tagMatches | ForEach-Object { $_.Groups[1].Value })
      $records.Add([pscustomobject]@{ num = $num; name = $name; group = $group; tags = $tags; line = $line.Trim() }) | Out-Null
    }
  }

  try {
    $enc = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($cachePath, ($records | ConvertTo-Json -Depth 6 -Compress), $enc)
  } catch { }  # cache-write failure must never break the actual parse result

  return $records
}
