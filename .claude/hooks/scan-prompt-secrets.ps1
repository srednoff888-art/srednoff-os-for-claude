# UserPromptSubmit hook - block the prompt itself if it appears to contain a real secret
# (pasted API key, private key, JWT, etc). Ported concept from srednoff-os (Codex sibling).
# Confirmed contract (code.claude.com/docs, 2026-07-01): block via {"decision":"block","reason":...}.
# Wire: powershell -NoProfile -ExecutionPolicy Bypass -File .claude/hooks/scan-prompt-secrets.ps1
$ErrorActionPreference = "SilentlyContinue"
. "$PSScriptRoot\hook-lib.ps1"

$raw = [Console]::In.ReadToEnd()
if (-not $raw) { exit 0 }
try { $p = $raw | ConvertFrom-Json } catch { exit 0 }

$text = "$($p.prompt)"
if (-not $text) { $text = $raw }   # fallback: scan the raw payload if the prompt field name differs

$hits = Find-SecretSignals -Text $text
if ($hits.Count -gt 0) {
  Write-HookLedger -HookScript "scan-prompt-secrets" -Decision "block" -Findings $hits -RawInput $raw
  $reason = "Your message appears to contain a secret ($($hits -join ', ')). Blocked before submission by Claude MD OS. Remove the secret and resend, or store it in .env instead."
  Write-Output (@{ decision = "block"; reason = $reason } | ConvertTo-Json -Compress)
  exit 0
}
exit 0
