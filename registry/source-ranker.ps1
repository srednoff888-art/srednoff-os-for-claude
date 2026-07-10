# SREDNOFF OS source ranker - scores external UI/3D/design/growth sources for a task
# brief against design-source-registry.json (license/provenance/vetted/copy_policy
# metadata), so the agent gets a ranked shortlist with explicit gates instead of
# picking a component source by memory. Ported and adapted from srednoff-os (Codex
# sibling): srednoff-os-source-ranker.ps1 - concept and scoring logic only, rewritten
# for this repo's registry layout and mode-router.ps1 JSON shape.
# ASCII-only on purpose: Windows PowerShell 5.1 misparses non-ASCII .ps1 without BOM.
param(
    [string]$ProjectPath = ".",
    [AllowEmptyString()]
    [string]$Brief = "",
    [int]$Max = 8,
    [switch]$Json
)

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RegistryPath = Join-Path $ScriptDir "design-source-registry.json"
$InventoryPath = Join-Path $ScriptDir "mcp-inventory.json"
$ModeRouter = Join-Path $ScriptDir "mode-router.ps1"

if (-not (Test-Path -LiteralPath $RegistryPath -PathType Leaf)) {
    throw "design source registry not found: $RegistryPath"
}

$Lower = $Brief.ToLowerInvariant()

function Test-Any {
    param([string[]]$Patterns)
    foreach ($Pattern in $Patterns) {
        if ($Lower -match $Pattern) { return $true }
    }
    return $false
}

function ConvertTo-MatchKey {
    param([string]$Value)
    return ([string]$Value).ToLowerInvariant() -replace '[^a-z0-9]+', ''
}

$BriefKey = ConvertTo-MatchKey -Value $Brief

$Domains = New-Object System.Collections.Generic.List[string]
if (Test-Any @('ui/ux','ux','ui\b','web design','landing','dashboard','component','shadcn','figma','canva','21st','magic ui','aceternity','origin ui','react bits','design','interface','ui kit')) {
    $Domains.Add("ui-ux") | Out-Null
    $Domains.Add("web-design") | Out-Null
}
if (Test-Any @('\b3d\b','three','react three fiber','r3f','webgl','webgpu','gltf','glb','model-viewer','babylon','shader','xr','ar\b','configurator','asset','model','texture','hdri')) {
    $Domains.Add("3d-web") | Out-Null
}
if (Test-Any @('seo','ppc','growth','ads','google ads','meta ads','serp','conversion','analytics')) {
    $Domains.Add("seo-ppc-growth") | Out-Null
    $Domains.Add("growth") | Out-Null
}
if ($Domains.Count -eq 0) {
    $Domains.Add("ui-ux") | Out-Null
    $Domains.Add("web-design") | Out-Null
}
$DomainList = @($Domains.ToArray() | Select-Object -Unique)

# External process invocation silently drops an empty-string argument value (a real
# Windows/PowerShell quirk found while adding an empty-brief eval fixture), so -Brief ""
# would bind -Json's value to -Brief instead and fail with "missing argument". Guard by
# skipping the external call entirely for an empty brief - mode-router.ps1 would just
# classify empty text as "standard" anyway.
$Mode = if ($Brief -and (Test-Path -LiteralPath $ModeRouter -PathType Leaf)) {
    & powershell -NoProfile -ExecutionPolicy Bypass -File $ModeRouter -Brief $Brief -Json | ConvertFrom-Json
} else {
    [pscustomobject]@{ mode = "standard"; turbo = $false }
}

$Inventory = $null
if (Test-Path -LiteralPath $InventoryPath -PathType Leaf) {
    try { $Inventory = Get-Content -LiteralPath $InventoryPath -Raw -Encoding UTF8 | ConvertFrom-Json } catch { $Inventory = $null }
}

function Test-ConnectorEnabled {
    param([string]$Connector)
    if (-not $Connector -or -not $Inventory) { return $false }
    $Items = @($Inventory.items | Where-Object { $_.name -eq $Connector -and $_.enabled })
    return $Items.Count -gt 0
}

function Resolve-PathOrLiteral {
    param([string]$Path)
    try {
        if (Test-Path -LiteralPath $Path) {
            return (Resolve-Path -LiteralPath $Path).Path
        }
    } catch {
        return $Path
    }
    return $Path
}

function Get-RiskPenalty {
    param([string]$Risk)
    switch ($Risk) {
        "low" { return 2.0 }
        "medium" { return 0.0 }
        "high" { return -4.0 }
        default { return -1.0 }
    }
}

$Registry = Get-Content -LiteralPath $RegistryPath -Raw -Encoding UTF8 | ConvertFrom-Json
$Ranked = foreach ($Source in $Registry.sources) {
    $Score = 0.0
    $Reasons = New-Object System.Collections.Generic.List[string]
    $Gates = New-Object System.Collections.Generic.List[string]

    $SourceDomains = @($Source.domains)
    $DomainMatches = @($SourceDomains | Where-Object { $DomainList -contains $_ })
    if ($DomainMatches.Count -gt 0) {
        $Score += 10.0 * $DomainMatches.Count
        $Reasons.Add("domain:$($DomainMatches -join ',')") | Out-Null
    }

    $NameBlob = (($Source.id, $Source.name, $Source.kind) -join " ").ToLowerInvariant()
    $NameKey = ConvertTo-MatchKey -Value $NameBlob
    foreach ($Term in @($Source.use_when)) {
        if ($Lower.Contains(([string]$Term).ToLowerInvariant())) {
            $Score += 3.0
            $Reasons.Add("use_when:$Term") | Out-Null
        }
    }
    foreach ($Token in @("shadcn","21st","magic","aceternity","origin","react bits","figma","canva","three","r3f","gltf","glb","model-viewer","babylon","sketchfab","poly haven","ambientcg")) {
        $TokenKey = ConvertTo-MatchKey -Value $Token
        if (($Lower.Contains($Token) -or $BriefKey.Contains($TokenKey)) -and $NameKey.Contains($TokenKey)) {
            $Score += 6.0
            $Reasons.Add("named:$Token") | Out-Null
        }
    }

    if ((Test-Any @('ui kit','component','components','landing','dashboard')) -and ([string]$Source.kind -match 'component|registry|marketplace|design')) {
        $Score += 4.0
        $Reasons.Add("ui-source-fit") | Out-Null
    }
    if ((Test-Any @('3d asset','3d assets','gltf','glb','\bmodel\b','\btexture\b','\bhdri\b','\bar\b')) -and ((@($Source.domains) -contains "3d-web") -or ([string]$Source.kind -match '3d|asset|model|texture|optimizer'))) {
        $Score += 5.0
        $Reasons.Add("3d-asset-fit") | Out-Null
    }
    if ($Mode.mode -eq "turbo" -or [bool]$Mode.turbo) {
        $Score += 2.0
        $Reasons.Add("turbo-benchmark") | Out-Null
    }

    $License = ([string]$Source.license).Trim()
    $Provenance = ([string]$Source.provenance).Trim()
    $CopyPolicy = ([string]$Source.copy_policy).Trim()

    $Score += Get-RiskPenalty -Risk ([string]$Source.risk)
    if ([bool]$Source.vetted) {
        $Score += 1.5
        $Reasons.Add("vetted-source") | Out-Null
    } else {
        $Score -= 0.5
        $Gates.Add("unvetted-source-review") | Out-Null
    }
    if (-not $License) {
        $Score -= 3.0
        $Gates.Add("missing-license-metadata") | Out-Null
    } elseif ($License -match 'varies|verify|user-provided') {
        $Score -= 0.5
        $Gates.Add("license-provenance-review") | Out-Null
    } else {
        $Score += 0.75
        $Reasons.Add("known-license") | Out-Null
    }
    if (-not $Provenance) {
        $Score -= 2.0
        $Gates.Add("missing-provenance-metadata") | Out-Null
    }
    if (-not $CopyPolicy) {
        $Score -= 1.0
        $Gates.Add("missing-copy-policy") | Out-Null
    }
    if ([bool]$Source.requires_user_prompt) {
        $Score -= 0.5
        $Gates.Add("ask-user-before-connector-or-external-copy") | Out-Null
    }
    if ($Source.connector) {
        if (Test-ConnectorEnabled -Connector ([string]$Source.connector)) {
            $Score += 2.0
            $Reasons.Add("connector-enabled:$($Source.connector)") | Out-Null
        } else {
            $Score -= 1.0
            $Gates.Add("connector-availability-check") | Out-Null
        }
    }
    if ([string]$Source.risk -ne "low") {
        $Gates.Add("license-provenance-review") | Out-Null
    }
    if ((@($Source.domains) -contains "3d-web") -or ([string]$Source.kind -match '3d|asset|model|texture|optimizer')) {
        $Gates.Add("asset-size-performance-budget") | Out-Null
    }
    if ([string]$Source.kind -match 'component|registry|marketplace|design') {
        $Gates.Add("accessibility-responsive-visual-qa") | Out-Null
    }

    [pscustomobject]@{
        id = $Source.id
        name = $Source.name
        url = $Source.url
        kind = $Source.kind
        risk = $Source.risk
        score = [math]::Round($Score, 2)
        reasons = @($Reasons.ToArray() | Select-Object -Unique)
        gates = @($Gates.ToArray() | Select-Object -Unique)
        license = $License
        provenance = $Provenance
        vetted = [bool]$Source.vetted
        copy_policy = $CopyPolicy
        connector = $Source.connector
        requires_user_prompt = [bool]$Source.requires_user_prompt
    }
}

$Ranked = @($Ranked | Sort-Object score -Descending | Select-Object -First $Max)

$Result = [ordered]@{
    name = "SREDNOFF OS source ranker"
    project = Resolve-PathOrLiteral -Path $ProjectPath
    mode = $Mode.mode
    domains = @($DomainList)
    ranked_sources = $Ranked
}

if ($Json) {
    $Result | ConvertTo-Json -Depth 8
} else {
    Write-Output "SREDNOFF OS source ranking: mode=$($Mode.mode) | domains=$($DomainList -join ', ') | sources=$($Ranked.Count)"
    foreach ($Source in $Ranked) {
        Write-Output ("- {0} | score={1} | risk={2} | gates={3}" -f $Source.name, $Source.score, $Source.risk, (@($Source.gates) -join ","))
    }
}
