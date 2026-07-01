# Shared library for Claude MD OS hooks. Dot-source: . "$PSScriptRoot\hook-lib.ps1"
# Ported concepts from srednoff-os (Codex sibling project): content-based secret scan + audit ledger.

function Get-Sha256Hex {
  param([string]$Text)
  $sha = [System.Security.Cryptography.SHA256]::Create()
  $bytes = [System.Text.Encoding]::UTF8.GetBytes($Text)
  $hash = $sha.ComputeHash($bytes)
  return (($hash | ForEach-Object { $_.ToString("x2") }) -join "")
}

# Privacy-safe audit trail: logs ONLY when something is flagged (secret/dangerous pattern),
# not every tool call — keeps the log meaningful instead of a firehose. Stores a sha256 of
# the raw hook input, never the input itself, so no secret content ever lands on disk here.
function Write-HookLedger {
  param(
    [string]$HookScript,
    [string]$Decision,
    [string[]]$Findings,
    [string]$RawInput
  )
  $logDir = Join-Path $env:USERPROFILE ".claude\logs"
  New-Item -ItemType Directory -Force -Path $logDir -ErrorAction SilentlyContinue | Out-Null
  # session_id correlation (concept adapted from paperclipai/paperclip's run-ID audit trail,
  # MIT - their pattern stamps every mutating API call with a run ID; ours stamps every hook
  # decision with Claude Code's own session_id, present at the top level of every hook JSON
  # payload per official docs). Lets you grep hook-events.jsonl for everything that happened
  # within one specific session.
  $sessionId = $null
  if ($RawInput) { try { $sessionId = ($RawInput | ConvertFrom-Json).session_id } catch {} }
  $entry = [ordered]@{
    ts           = (Get-Date).ToUniversalTime().ToString("o")
    hook         = $HookScript
    decision     = $Decision
    findings     = @($Findings)
    session_id   = $sessionId
    input_sha256 = if ($RawInput) { Get-Sha256Hex -Text $RawInput } else { $null }
  }
  $line = ($entry | ConvertTo-Json -Compress -Depth 6) + [Environment]::NewLine
  $path = Join-Path $logDir "hook-events.jsonl"
  $enc = New-Object System.Text.UTF8Encoding($false)
  for ($i = 1; $i -le 3; $i++) {
    try { [System.IO.File]::AppendAllText($path, $line, $enc); return } catch { if ($i -eq 3) { return }; Start-Sleep -Milliseconds (100 * $i) }
  }
}

# Content-based secret scan (not just filename heuristics). Scans whatever text is passed in
# (a bash command, a file's new content, a diff string) for real secret-shaped patterns.
function Find-SecretSignals {
  param([string]$Text)
  if (-not $Text) { return @() }
  # Patterns cross-checked against gitleaks.toml (authoritative open-source secret-pattern DB)
  # and Slack's own token format, 2026-07-01. Supabase/Vercel have no distinctive fixed-prefix
  # token format documented anywhere reputable as of this check, so no pattern is claimed for
  # them (Supabase service-role keys are JWTs and are already caught by the jwt rule below).
  $rules = @(
    @{ Name = "openai_api_key"; Pattern = "sk-[A-Za-z0-9_-]{32,}" },
    @{ Name = "anthropic_api_key"; Pattern = "sk-ant-[A-Za-z0-9_-]{20,}" },
    @{ Name = "github_token"; Pattern = "gh[pousr]_[A-Za-z0-9_]{32,}" },
    @{ Name = "aws_access_key"; Pattern = "AKIA[0-9A-Z]{16}" },
    @{ Name = "google_api_key"; Pattern = "AIza[0-9A-Za-z_-]{35}" },
    @{ Name = "private_key"; Pattern = "-----BEGIN (RSA |DSA |EC |OPENSSH |)?PRIVATE KEY-----" },
    @{ Name = "jwt"; Pattern = "eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}" },
    @{ Name = "stripe_key"; Pattern = "\b(sk|rk)_(test|live|prod)_[A-Za-z0-9]{10,99}" },
    @{ Name = "slack_token"; Pattern = "xox[pbao]-[0-9]{10,13}-[0-9]{10,13}-[0-9]{10,13}-[a-f0-9]{32}" },
    @{ Name = "slack_webhook"; Pattern = "hooks\.slack\.com/services/T[A-Za-z0-9]{8,}/B[A-Za-z0-9]{8,}/[A-Za-z0-9]{20,}" },
    @{ Name = "twilio_key"; Pattern = "SK[0-9a-fA-F]{32}" },
    @{ Name = "sendgrid_key"; Pattern = "SG\.[A-Za-z0-9=_.-]{60,}" },
    @{ Name = "npm_token"; Pattern = "npm_[A-Za-z0-9]{36}" },
    # Added via security-audit review, 2026-07-01: GCP service-account JSON keys embed their
    # PEM as a JSON-escaped string ("-----BEGIN PRIVATE KEY-----\n...") - the multi-line
    # private_key regex above does NOT match escaped \n, so it silently misses this very
    # common credential shape. private_key_id is GCP's own documented 40-char hex field name.
    @{ Name = "gcp_service_account_key"; Pattern = '"private_key_id"\s*:\s*"[a-f0-9]{40}"' },
    # Generic DB connection string with an embedded password (postgres/mysql/mongodb/redis/amqp).
    @{ Name = "db_connection_string"; Pattern = '(postgres(ql)?|mysql|mongodb(\+srv)?|redis|amqp):\/\/[^:\/\s"'']+:[^@\/\s"'']+@' }
  )
  $findings = @()
  foreach ($r in $rules) { if ($Text -match $r.Pattern) { $findings += $r.Name } }
  return @($findings | Select-Object -Unique)
}
