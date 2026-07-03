# PostToolUse(Read) hook - records that this session actually read PROFILE.lock.md or
# CORE-300.md, so require-profile-lock-read.ps1 (PreToolUse Edit|Write|MultiEdit) can verify
# real engagement instead of trusting that the agent noticed the banner in CLAUDE.md.
#
# WHY THIS EXISTS (found via real-world case review, 2026-07-02): a fully-deployed project
# had SREDNOFF-OS:ACTIVE banner + the tagged skill shortlist embedded directly in the first
# 6 lines of CLAUDE.md (always-loaded) - and the agent still never called Skill(), never
# grepped CORE-300.md, never did GitHub Research for non-trivial architecture decisions.
# Conclusion: information being present in context does not equal compliance. Passive text,
# even prominently placed, is not enforcement. Hooks are the only real enforcement mechanism
# in Claude Code, so this pair of hooks turns "read PROFILE.lock first" (rule 70) from an
# instruction into an actual gate.
$ErrorActionPreference = "SilentlyContinue"

$raw = [Console]::In.ReadToEnd()
if (-not $raw) { exit 0 }
try { $p = $raw | ConvertFrom-Json } catch { exit 0 }

$sessionId = $p.session_id
$filePath = "$($p.tool_input.file_path)"
if (-not $sessionId -or -not $filePath) { exit 0 }

if ($filePath -notmatch 'PROFILE\.lock\.md$' -and $filePath -notmatch 'CORE-300\.md$') { exit 0 }

try {
  $stateDir = Join-Path $env:USERPROFILE ".claude\logs\session-state\$sessionId"
  New-Item -ItemType Directory -Force -Path $stateDir -ErrorAction SilentlyContinue | Out-Null
  New-Item -ItemType File -Force -Path (Join-Path $stateDir "profile-lock-read.marker") -ErrorAction SilentlyContinue | Out-Null
} catch {}
exit 0
