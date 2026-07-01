#!/usr/bin/env bash
# Global SessionStart hook for SREDNOFF OS (Linux/macOS port of session-start-hook.ps1).
# - If a project under the workspace root lacks the OS -> auto-apply it (non-destructive).
# - If the OS is present -> emit an "OS ACTIVE" banner so it visibly engages in the project window.
# Idempotent, scoped to the workspace root. Requires: jq.
#
# Wiring (~/.claude/settings.json):
#   "hooks": { "SessionStart": [{ "hooks": [{ "type": "command",
#     "command": "bash \"$HOME/.claude/templates/claude-md-os/scripts/global/session-start-hook.sh\"" }] }] }
#
# Set SREDNOFF_OS_ROOT to the workspace folder you want auto-managed (e.g. "/home/me/projects").
# If unset, defaults to $HOME - the hook only ever acts on real project folders it finds
# there (package.json / .git / *.md present), never on arbitrary directories.
set -uo pipefail

raw="$(cat)"
cwd=""
if [ -n "$raw" ] && command -v jq >/dev/null 2>&1; then
  cwd="$(printf '%s' "$raw" | jq -r '.cwd // .workspace.current_dir // empty' 2>/dev/null || true)"
fi
[ -z "$cwd" ] && cwd="$(pwd)"

# LIVENESS LEDGER: logs EVERY invocation unconditionally, before any early-exit, with the
# real PID and a "source" field distinguishing genuine SessionStart calls (source=startup/
# resume/clear/compact, set by Claude Code itself) from a manual test (empty/absent when
# someone pipes JSON in by hand). Lets you independently verify the hook has EVER actually
# fired through the real runtime, not just through self-administered tests.
if command -v jq >/dev/null 2>&1; then
  log_dir="$HOME/.claude/logs"
  mkdir -p "$log_dir" 2>/dev/null || true
  source_field="unknown-or-manual"
  if [ -n "$raw" ]; then
    s="$(printf '%s' "$raw" | jq -r '.source // empty' 2>/dev/null || true)"
    [ -n "$s" ] && source_field="$s"
  fi
  session_id_field="$(printf '%s' "$raw" | jq -r '.session_id // empty' 2>/dev/null || true)"
  ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  jq -nc --arg ts "$ts" --argjson pid "$$" --arg cwd "$cwd" --arg source "$source_field" --arg session_id "$session_id_field" \
    '{ts: $ts, pid: $pid, cwd: $cwd, source: $source, session_id: (if $session_id == "" then null else $session_id end)}' >> "$log_dir/hook-liveness.jsonl" 2>/dev/null || true
fi

root_guard="${SREDNOFF_OS_ROOT:-$HOME}"
case "$cwd" in
  "$root_guard"*) ;;   # inside workspace -> continue
  *) exit 0 ;;         # outside workspace -> ignore
esac
[ "${cwd%/}" = "${root_guard%/}" ] && exit 0   # the root itself -> ignore

name="$(basename "$cwd")"
has_os=0
[ -f "$cwd/.claude/rules/00-operating-system.md" ] && has_os=1

emit() {
  local msg="$1"
  if command -v jq >/dev/null 2>&1; then
    jq -nc --arg msg "$msg" '{hookSpecificOutput: {hookEventName: "SessionStart", additionalContext: $msg}}'
  fi
}

if [ "$has_os" -eq 1 ]; then
  tags=""
  lock="$cwd/.claude/PROFILE.lock.md"
  if [ -f "$lock" ]; then
    tags="$(grep -m1 -E '^`[^`]+`$' "$lock" | sed 's/^`//; s/`$//')"
  fi
  banner="SREDNOFF OS ACTIVE in project '$name'. Operating rules: Principle #1 (quality first, economy only at equal quality); rules 00-90 loaded (github-research, quality-gate, security, exec-plans, skills-registry, model-routing G1~Haiku/G2~Sonnet/G3~Opus, subagent-contract). PROFILE.lock"
  [ -n "$tags" ] && banner="$banner [tags: $tags]"
  banner="$banner. Full skill registry available on demand (~/.claude/registry/CORE-300.md, see version.json for current record count). External agents = unvetted until github-research."
  emit "$banner"
  exit 0
fi

# OS missing: only act on real project folders.
looks_project=0
if [ -f "$cwd/package.json" ] || [ -d "$cwd/.git" ] || find "$cwd" -maxdepth 1 -name "*.md" -print -quit 2>/dev/null | grep -q .; then
  looks_project=1
fi
[ "$looks_project" -eq 0 ] && exit 0

init="$HOME/.claude/templates/claude-md-os/scripts/init-claude-project.sh"
[ -f "$init" ] || exit 0

bash "$init" "$cwd" --skip-existing-claude-md >/dev/null 2>&1 || true
emit "SREDNOFF OS was AUTO-APPLIED to project '$name' (it was missing) and is now ACTIVE: rules 00-90 + PROFILE.lock generated. Operating under Principle #1 (quality first)."
exit 0
