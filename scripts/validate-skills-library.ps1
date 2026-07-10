# Fast metadata smoke check for templates/claude-md-os/skills-library/*/SKILL.md - name
# pattern, description length/presence, frontmatter well-formedness. Ported concept from
# srednoff-os (Codex sibling): quick-validate-all-skills.ps1 "fast" mode (their "full" mode
# shells out to an external Codex-specific validator we don't have and don't need - our
# skills are pre-vetted at import time, this check just guards against future drift/typos).
# ASCII-only on purpose: Windows PowerShell 5.1 misparses non-ASCII .ps1 without BOM.
param(
    [string]$SkillsRoot = "$PSScriptRoot\..\skills-library",
    [switch]$Json
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $SkillsRoot)) {
    Write-Output "skills-library not found: $SkillsRoot (nothing to validate)"
    if ($Json) { @{ ok = 0; failed = 0 } | ConvertTo-Json }
    exit 0
}

$SkillDirs = Get-ChildItem -LiteralPath $SkillsRoot -Directory |
    Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName "SKILL.md") }

$Ok = 0
$Failures = New-Object System.Collections.Generic.List[object]

foreach ($Skill in $SkillDirs) {
    $SkillFile = Join-Path $Skill.FullName "SKILL.md"
    $Text = Get-Content -LiteralPath $SkillFile -Raw -Encoding UTF8
    $Lines = $Text -split "`r?`n"
    $NameOk = $false
    $DescriptionOk = $false
    for ($i = 0; $i -lt $Lines.Count; $i++) {
        $Line = $Lines[$i]
        if ($Line -match '^\s*---\s*$' -and $i -gt 0) { break }
        # -cmatch (case-sensitive): PowerShell's default -match is case-insensitive,
        # which would accept "Name: BadUpperCaseName" as a valid lowercase name - a real
        # Claude Code skill name must be lowercase (official docs), and bash's grep -Eq
        # (case-sensitive by default) already rejects this correctly. An unqualified
        # -match here would silently let an invalid skill pass on Windows while bash
        # correctly failed it - a real platform-parity bug, not cosmetic.
        if ($Line -cmatch '^\s*name:\s*[a-z0-9][a-z0-9-]{1,62}\s*$') { $NameOk = $true }
        if ($Line -match '^\s*description:\s*(.+)$') {
            $Value = $Matches[1].Trim()
            if ($Value -in @(">", "|", ">-", "|-", ">+", "|+")) {
                # YAML block scalar - the actual description is the indented lines that
                # follow, not this marker itself. None of the 303 currently-imported
                # skills use this form, but it's a standard YAML pattern real skills in
                # this ecosystem do use (confirmed in the donor catalog) - treating it as
                # a 1-character description would be a false failure on a well-formed skill.
                $BlockLines = @()
                for ($Child = $i + 1; $Child -lt $Lines.Count; $Child++) {
                    if ($Lines[$Child] -match '^\s*---\s*$') { break }
                    if ($Lines[$Child] -match '^\s+\S') { $BlockLines += $Lines[$Child].Trim() } else { break }
                }
                $BlockValue = ($BlockLines -join " ").Trim()
                $DescriptionOk = ($BlockValue.Length -ge 20) -and ($BlockValue.Length -le 1024)
            } else {
                $Value = $Value.Trim('"').Trim("'")
                $DescriptionOk = ($Value.Length -ge 20) -and ($Value.Length -le 1024)
            }
        }
    }
    $Errors = @()
    if (-not $Text.StartsWith("---")) { $Errors += "missing frontmatter start" }
    if ($Skill.Name -ne $Skill.Name.ToLowerInvariant()) { $Errors += "directory name must be lowercase" }
    if (-not $NameOk) { $Errors += "missing or invalid name (lowercase, alnum+hyphen, 2-63 chars)" }
    if (-not $DescriptionOk) { $Errors += "missing, too-short (<20 chars), or too-long (>1024 chars) description" }

    if ($Errors.Count -eq 0) {
        $Ok++
    } else {
        $Failures.Add([pscustomobject]@{ skill = $Skill.Name; errors = ($Errors -join "; ") }) | Out-Null
    }
}

if ($Json) {
    [ordered]@{ ok = $Ok; failed = $Failures.Count; failures = $Failures } | ConvertTo-Json -Depth 4
} else {
    Write-Output "skills-library validation: ok=$Ok failed=$($Failures.Count)"
    foreach ($f in $Failures) { Write-Output "  FAIL $($f.skill): $($f.errors)" }
}

if ($Failures.Count -gt 0) { exit 1 }
exit 0
