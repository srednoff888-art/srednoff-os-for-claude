# Shared library for Claude MD OS hooks. Dot-source: . "$PSScriptRoot\hook-lib.ps1"
# Ported concepts from srednoff-os (Codex sibling project): content-based secret scan + audit ledger.

# --- Secret-like FILE PATHS ---------------------------------------------------------
# Lives here, not inside protect-secrets.ps1, so run-evals.ps1 can test these rules
# against fixtures. They had no fixtures at all before, which is exactly how the
# .env.example false positive shipped and survived: only CONTENT rules were ever tested.
$SecretPathPattern = '(^|[\\/])\.env(\.|$)|id_rsa|id_ed25519|\.pem$|\.key$|secrets?\.(json|ya?ml|toml)$|credentials(\.json)?$'

# Names that match the pattern above but are meant to be committed and edited. Every one
# of these was a real, reproduced denial that blocked ordinary work:
#   .env.example / .sample / .template / .dist - the file documenting which variables a
#     project needs. Denied even for Read, so the agent could not find out what to
#     configure. (The catalog already treats *.example as legitimate elsewhere:
#     'secrets?\.(json|ya?ml|toml)$' is anchored, so k8s/secrets.example.yaml was always
#     allowed - the .env branch was simply inconsistent with it.)
#   *.pub  - the PUBLIC half of a key pair; it belongs in authorized_keys and GitHub
#     deploy keys. There is no secret in it by definition.
#   ca-bundle/fullchain/chain.pem - public certificate chains, not private keys.
#   sealed-secrets / external-secrets / secret-store manifests - CONTROLLER configs that
#     reference a secret held elsewhere; that is the entire point of them.
#   fake_/mock_/test_/sample_ credentials.json - test fixtures.
# The allow-list is about the NAME only. Content is still checked - see
# Get-PathContentSignalsOnDisk below.
$SecretPathAllowPattern = '(^|[\\/])\.env(\.[A-Za-z0-9_-]+)*\.(example|sample|template|tpl|tmpl|dist|defaults?)(\.(j2|jinja|tpl|tmpl))?$|\.pub$|(^|[\\/])(ca-bundle|ca-certificates|cacert|fullchain|chain)\.pem$|(^|[\\/])(sealed-secrets?|external-secrets?|secret-?stores?)[^\\/]*\.ya?ml$|(^|[\\/])templates[\\/]secrets?\.ya?ml$|(^|[\\/])[^\\/]*(fake|mock|dummy|sample|example|test)[-_][^\\/]*credentials(\.json)?$'

# True = this path must be treated as a secret and denied.
function Test-SecretPath {
  param([string]$Path)
  if (-not $Path) { return $false }
  if ($Path -notmatch $SecretPathPattern) { return $false }
  # Matched the deny pattern - unless it is one of the known-safe names.
  if ($Path -match $SecretPathAllowPattern) { return $false }
  return $true
}

# True = the name looked secret-like but is on the allow-list above.
function Test-SecretPathAllowlisted {
  param([string]$Path)
  if (-not $Path) { return $false }
  if ($Path -notmatch $SecretPathPattern) { return $false }
  return ($Path -match $SecretPathAllowPattern)
}

# We vouch for an allow-listed NAME, never for its CONTENT: a real key committed into
# .env.example is still a leak, and that is the one case the name-based allow-list would
# otherwise wave through - including on Read, where there is no tool_input to scan. So
# read the file itself (capped at 256 KiB, enough for any config template) and return any
# secret signals found. Empty array if the file is clean or absent.
function Get-PathContentSignalsOnDisk {
  param([string]$Path)
  if (-not $Path) { return @() }
  if (-not (Test-Path -LiteralPath $Path -PathType Leaf -ErrorAction SilentlyContinue)) { return @() }
  try {
    $reader = [System.IO.File]::OpenText($Path)
    try {
      $buffer = New-Object char[] 262144
      $read = $reader.Read($buffer, 0, $buffer.Length)
      if ($read -le 0) { return @() }
      $text = -join $buffer[0..($read - 1)]
    } finally { $reader.Close() }
  } catch { return @() }
  return (Find-SecretSignals -Text $text)
}

function Get-Sha256Hex {
  param([string]$Text)
  $sha = [System.Security.Cryptography.SHA256]::Create()
  $bytes = [System.Text.Encoding]::UTF8.GetBytes($Text)
  $hash = $sha.ComputeHash($bytes)
  return (($hash | ForEach-Object { $_.ToString("x2") }) -join "")
}

# Privacy-safe audit trail: logs ONLY when something is flagged (secret/dangerous pattern),
# not every tool call - keeps the log meaningful instead of a firehose. Stores a sha256 of
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
    @{ Name = "openai_api_key"; Pattern = "(?<![A-Za-z0-9_-])sk-(proj-|svcacct-|admin-)?[A-Za-z0-9_-]{32,}" },
    @{ Name = "anthropic_api_key"; Pattern = "(?<![A-Za-z0-9_-])sk-ant-[A-Za-z0-9_-]{20,}" },
    @{ Name = "github_token"; Pattern = "(?<![A-Za-z0-9_-])gh[pousr]_[A-Za-z0-9_]{32,}" },
    @{ Name = "aws_access_key"; Pattern = "(?<![A-Za-z0-9_-])AKIA[0-9A-Z]{16}" },
    @{ Name = "google_api_key"; Pattern = "(?<![A-Za-z0-9_-])AIza[0-9A-Za-z_-]{35}" },
    @{ Name = "private_key"; Pattern = "-----BEGIN (RSA |DSA |EC |OPENSSH |)?PRIVATE KEY-----" },
    @{ Name = "jwt"; Pattern = "eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}" },
    @{ Name = "stripe_key"; Pattern = "\b(sk|rk)_(test|live|prod)_[A-Za-z0-9]{10,99}" },
    @{ Name = "slack_token"; Pattern = "xox[pbao]-[0-9]{10,13}-[0-9]{10,13}-[0-9]{10,13}-[a-f0-9]{32}" },
    @{ Name = "slack_webhook"; Pattern = "hooks\.slack\.com/services/T[A-Za-z0-9]{8,}/B[A-Za-z0-9]{8,}/[A-Za-z0-9]{20,}" },
    @{ Name = "twilio_key"; Pattern = "(?<![A-Za-z0-9_-])SK[0-9a-fA-F]{32}(?![0-9A-Za-z])" },
    @{ Name = "sendgrid_key"; Pattern = "SG\.[A-Za-z0-9=_.-]{60,}" },
    @{ Name = "npm_token"; Pattern = "(?<![A-Za-z0-9_-])npm_[A-Za-z0-9]{36}" },
    # Added via security-audit review, 2026-07-01: GCP service-account JSON keys embed their
    # PEM as a JSON-escaped string ("-----BEGIN PRIVATE KEY-----\n...") - the multi-line
    # private_key regex above does NOT match escaped \n, so it silently misses this very
    # common credential shape. private_key_id is GCP's own documented 40-char hex field name.
    @{ Name = "gcp_service_account_key"; Pattern = '"private_key_id"\s*:\s*"[a-f0-9]{40}"' },
    # Generic DB connection string with an embedded password (postgres/mysql/mongodb/redis/amqp).
    @{ Name = "db_connection_string"; Pattern = '(postgres(ql)?(\+[a-z0-9_]+)?|mysql|mongodb(\+srv)?|redis|amqp):\/\/[^:\/\s"'']+:(?!\$|\{\{|%\(|<|__)(?!(password|passwd|pass|changeme|change_me|secret|postgres|mysql|root|admin|example|placeholder|dummy|test|your_password|yourpassword)[@\/\s"''])[^@\/\s"'']+@' }
  )
  $findings = @()
  foreach ($r in $rules) { if ($Text -match $r.Pattern) { $findings += $r.Name } }
  return @($findings | Select-Object -Unique)
}
