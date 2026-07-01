# PreToolUse(Read|Edit|Write|MultiEdit) hook - block secret-like FILE PATHS and, separately,
# actual secret-shaped CONTENT being written (content-based, not just filename heuristics).
# PowerShell, no jq. Wire: powershell -NoProfile -ExecutionPolicy Bypass -File .claude/hooks/protect-secrets.ps1
$ErrorActionPreference = "SilentlyContinue"
. "$PSScriptRoot\hook-lib.ps1"

$raw = [Console]::In.ReadToEnd()
if (-not $raw) { exit 0 }
try { $p = $raw | ConvertFrom-Json } catch { exit 0 }

function Deny([string]$Reason, [string[]]$Findings) {
  Write-HookLedger -HookScript "protect-secrets" -Decision "deny" -Findings $Findings -RawInput $raw
  $out = @{ hookSpecificOutput = @{
    hookEventName = "PreToolUse"
    permissionDecision = "deny"
    permissionDecisionReason = $Reason
  } } | ConvertTo-Json -Depth 6 -Compress
  Write-Output $out
  exit 0
}

$fp = "$($p.tool_input.file_path)"
if (-not $fp) { $fp = "$($p.tool_input.path)" }

$secretPathPattern = '(^|[\\/])\.env(\.|$)|id_rsa|id_ed25519|\.pem$|\.key$|secrets?\.(json|ya?ml|toml)$|credentials(\.json)?$'
if ($fp -and ($fp -match $secretPathPattern)) {
  Deny "Secret-like file path blocked by Claude MD OS hook. Ask the user for explicit approval; use a redacted approach." @("secret_path")
}

# Content-based check: catches a secret being written into an otherwise-innocuous file
# (e.g. hardcoded into a .ts/.py source file), which the path check above cannot see.
$content = "$($p.tool_input.content)" + "`n" + "$($p.tool_input.new_string)" + "`n" + "$($p.tool_input.old_string)"
$secretHits = Find-SecretSignals -Text $content
if ($secretHits.Count -gt 0) {
  Deny "Content appears to contain a secret ($($secretHits -join ', ')). Blocked by Claude MD OS hook." $secretHits
}
exit 0
