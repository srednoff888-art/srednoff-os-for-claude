# PreToolUse(Edit|Write|MultiEdit) hook - denies the FIRST edit/write of a session in a
# project that has SREDNOFF OS deployed (.claude\PROFILE.lock.md exists) until the agent has
# actually read PROFILE.lock.md or CORE-300.md this session (tracked by
# mark-profile-lock-read.ps1, a companion PostToolUse hook). Once read once, every
# subsequent edit in the same session passes through freely - this is a one-time
# "did you orient yourself" gate, not a per-action gate.
#
# WHY THIS EXISTS: see mark-profile-lock-read.ps1's header. Embedding the skill shortlist
# directly into the first lines of CLAUDE.md (always-loaded) was tried first and was NOT
# sufficient - an agent read right past it without acting on rule 70's "read PROFILE.lock
# first." Passive text in context is not enforcement. This hook makes it one.
#
# DESIGN: fail-open by intent. This is a workflow-compliance nudge, not a security control -
# unlike block-dangerous-bash/protect-secrets (which SHOULD fail closed on ambiguity), a bug
# here must never become an unbreakable blocker. Any missing session_id, unreadable project
# state, or hook error results in ALLOW, never deny.
$ErrorActionPreference = "SilentlyContinue"

$raw = [Console]::In.ReadToEnd()
if (-not $raw) { exit 0 }
try { $p = $raw | ConvertFrom-Json } catch { exit 0 }

$sessionId = $p.session_id
$cwd = "$($p.cwd)"
if (-not $sessionId -or -not $cwd) { exit 0 }

$lockPath = Join-Path $cwd ".claude\PROFILE.lock.md"
if (-not (Test-Path -LiteralPath $lockPath)) { exit 0 }   # OS not deployed here - nothing to gate

$markerPath = Join-Path $env:USERPROFILE ".claude\logs\session-state\$sessionId\profile-lock-read.marker"
if (Test-Path -LiteralPath $markerPath) { exit 0 }   # already satisfied this session

$out = @{ hookSpecificOutput = @{
  hookEventName = "PreToolUse"
  permissionDecision = "deny"
  permissionDecisionReason = "This project has SREDNOFF OS active (.claude\PROFILE.lock.md exists) and it has not been read yet this session. Read .claude\PROFILE.lock.md (or grep registry\CORE-300.md by tag - see 70-skills-registry.md) to see the tagged skill shortlist for this stack, then retry this edit. This is a one-time check per session."
} } | ConvertTo-Json -Depth 6 -Compress
Write-Output $out
exit 0
