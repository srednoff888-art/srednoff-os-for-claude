# Global SessionStart hook for SREDNOFF OS (Windows/PowerShell).
# - If a project under the workspace root lacks the OS -> auto-apply it (non-destructive).
# - If the OS is present -> emit an "OS ACTIVE" banner so it visibly engages in the project window.
# Idempotent, scoped to the workspace root, ASCII-only (PS 5.1 safe).
#
# Wiring (~/.claude/settings.json):
#   "hooks": { "SessionStart": [{ "hooks": [{ "type": "command",
#     "command": "powershell -NoProfile -ExecutionPolicy Bypass -File \"$env:USERPROFILE\\.claude\\templates\\claude-md-os\\scripts\\global\\session-start-hook.ps1\"" }] }] }
#
# Set SREDNOFF_OS_ROOT to the workspace folder you want auto-managed (e.g. "D:\Projects").
# If unset, defaults to $HOME - the hook only ever acts on real project folders it finds
# there (package.json / .git / *.md present), never on arbitrary directories.
$ErrorActionPreference = "SilentlyContinue"

$raw = [Console]::In.ReadToEnd()
$cwd = $null
if ($raw) { try { $j = $raw | ConvertFrom-Json; $cwd = $j.cwd; if (-not $cwd) { $cwd = $j.workspace.current_dir } } catch {} }
if (-not $cwd) { $cwd = (Get-Location).Path }

# LIVENESS LEDGER: logs EVERY invocation unconditionally, before any early-exit, with the
# real PID and a "source" field distinguishing genuine SessionStart calls (source=startup/
# resume/clear/compact, set by Claude Code itself) from a manual test (source will be
# absent/empty when someone pipes JSON in by hand). Lets you independently verify the hook
# has EVER actually fired through the real runtime, not just through self-administered tests.
try {
  $logDir = Join-Path $env:USERPROFILE ".claude\logs"
  New-Item -ItemType Directory -Force -Path $logDir -ErrorAction SilentlyContinue | Out-Null
  $source = if ($j -and $j.source) { [string]$j.source } else { "unknown-or-manual" }
  $entry = [ordered]@{
    ts     = (Get-Date).ToUniversalTime().ToString("o")
    pid    = $PID
    cwd    = $cwd
    source = $source
  }
  $line = ($entry | ConvertTo-Json -Compress -Depth 4) + [Environment]::NewLine
  $enc = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::AppendAllText((Join-Path $logDir "hook-liveness.jsonl"), $line, $enc)
} catch {}

$rootGuard = if ($env:SREDNOFF_OS_ROOT) { $env:SREDNOFF_OS_ROOT } else { $HOME }
if ($cwd -notlike "$rootGuard*") { exit 0 }                       # outside workspace -> ignore
if ($cwd.TrimEnd('\') -ieq $rootGuard.TrimEnd('\')) { exit 0 }     # the root itself -> ignore

$name = Split-Path -Leaf $cwd
$hasOS = Test-Path (Join-Path $cwd ".claude\rules\00-operating-system.md")

function Emit($msg) {
  $out = @{ hookSpecificOutput = @{ hookEventName = "SessionStart"; additionalContext = $msg } } | ConvertTo-Json -Compress
  Write-Output $out
}

if ($hasOS) {
  $tags = ""
  $lock = Join-Path $cwd ".claude\PROFILE.lock.md"
  if (Test-Path $lock) {
    $m = Select-String -Path $lock -Pattern '^`([^`]+)`$' | Select-Object -First 1
    if ($m) { $tags = $m.Matches[0].Groups[1].Value }
  }
  $banner = "SREDNOFF OS ACTIVE in project '$name'. Operating rules: Principle #1 (quality first, economy only at equal quality); rules 00-90 loaded (github-research, quality-gate, security, exec-plans, skills-registry, model-routing G1~Haiku/G2~Sonnet/G3~Opus, subagent-contract). PROFILE.lock"
  if ($tags) { $banner += " [tags: $tags]" }
  $banner += ". Full skill registry available on demand (~/.claude/registry/CORE-300.md, see version.json for current record count). External agents = unvetted until github-research."
  Emit $banner
  exit 0
}

# OS missing: only act on real project folders.
$looksProject = (Test-Path (Join-Path $cwd "package.json")) -or
                (Test-Path (Join-Path $cwd ".git")) -or
                (Get-ChildItem $cwd -Filter *.md -ErrorAction SilentlyContinue | Select-Object -First 1)
if (-not $looksProject) { exit 0 }

$init = Join-Path $env:USERPROFILE ".claude\templates\claude-md-os\scripts\init-claude-project.ps1"
if (-not (Test-Path $init)) { exit 0 }

& powershell -NoProfile -ExecutionPolicy Bypass -File $init $cwd -SkipExistingClaudeMd *> $null
Emit "SREDNOFF OS was AUTO-APPLIED to project '$name' (it was missing) and is now ACTIVE: rules 00-90 + PROFILE.lock generated. Operating under Principle #1 (quality first)."
exit 0
