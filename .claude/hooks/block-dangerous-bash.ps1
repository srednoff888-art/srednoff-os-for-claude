# PreToolUse(Bash|PowerShell) hook - block dangerous shell commands AND secrets in the command text.
# PowerShell, no jq needed. Wire via settings: powershell -NoProfile -ExecutionPolicy Bypass -File .claude/hooks/block-dangerous-bash.ps1
$ErrorActionPreference = "SilentlyContinue"
. "$PSScriptRoot\hook-lib.ps1"

$raw = [Console]::In.ReadToEnd()
if (-not $raw) { exit 0 }
try { $p = $raw | ConvertFrom-Json } catch { exit 0 }
$cmd = "$($p.tool_input.command)"
if (-not $cmd) { exit 0 }

function Deny([string]$Reason, [string[]]$Findings) {
  Write-HookLedger -HookScript "block-dangerous-bash" -Decision "deny" -Findings $Findings -RawInput $raw
  $out = @{ hookSpecificOutput = @{
    hookEventName = "PreToolUse"
    permissionDecision = "deny"
    permissionDecisionReason = $Reason
  } } | ConvertTo-Json -Depth 6 -Compress
  Write-Output $out
  exit 0
}

# Secret-in-command check (content-based, not just filename heuristics).
$secretHits = Find-SecretSignals -Text $cmd
if ($secretHits.Count -gt 0) {
  Deny "Command appears to contain a secret ($($secretHits -join ', ')). Blocked by Claude MD OS hook." $secretHits
}

# BUG FIXES (found via security-audit review, 2026-07-01):
# (1) 'rm -rf /*' and 'rm -rf ./*' wipe the same targets as bare '/' or '.' but bypassed the
#     old pattern's trailing (\s|$) requirement (a literal '/' followed by '*' is neither
#     whitespace nor end-of-string) - added an optional '(/\*)?' before the boundary check.
# (2) Long-form '--recursive --force' (either order) and reversed short flags '-fr' bypassed
#     the old pattern, which only matched the literal '-rf' token.
# (3) 'git push -f' (the common short flag) bypassed the old pattern, which only matched
#     '--force'.
# PowerShell-tool syntax (the PowerShell tool is a separate tool from Bash; with only a
# Bash matcher it skipped every hook): recursive Remove-Item / rd / del /s aimed at a
# drive root, the home directory, the current directory or a bare wildcard, and the
# disk-wiping cmdlets. A piped delete (Get-ChildItem -Recurse | Remove-Item) is NOT
# recognised.
$danger = @(
  '(^|\s)rm(\s+-[^\s]+)*\s+["'']?(/|~|\$HOME|\$\{HOME\}|\.)["'']?(\*|/\*)?["'']?(\s|$)',
  '\bmkfs\b',
  '\bdd\b.*\bof=/dev/',
  ':\(\)\s*\{\s*:\|\:&\s*\};:',     # fork bomb
  'chmod\s+-R\s+777\s+/',
  'git\s+push\s+.*(--force|-f)(\s|$)',
  'git\s+reset\s+--hard',
  '\bformat\s+[A-Za-z]:',
  '>\s*/dev/sd[a-z]',
  '(?i)\b(?:Remove-Item|ri|rm|rmdir|rd|del|erase)\b(?=[^;|&\n]*(?:-Recurse\b|\s/s\b))[^;|&\n]*?(?<=[\s\x22\x27=])(?:(?:~|\$HOME|\$\{HOME\}|\$env:(?:USERPROFILE|HOMEPATH|SystemDrive|SystemRoot|windir)|[A-Za-z]:|\.)(?:[\\/]\*?|\*)?|[\\/]\*?|\*)[\x22\x27]?(?=\s|$|[;|&)])',
  '(?i)\b(?:Format-Volume|Clear-Disk|Initialize-Disk|Remove-Partition)\b',
  '(?i)\bdiskpart\b'
)
foreach ($d in $danger) {
  if ($cmd -match $d) {
    Deny "Dangerous shell command blocked by Claude MD OS hook (pattern: $d)." @($d)
  }
}
exit 0
