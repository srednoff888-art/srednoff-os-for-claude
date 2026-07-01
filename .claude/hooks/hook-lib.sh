#!/usr/bin/env bash
# Shared library for SREDNOFF OS bash hooks (Linux/macOS port of hook-lib.ps1).
# Source it: . "$(dirname "$0")/hook-lib.sh"
# Requires: jq (JSON in/out), grep -P (PCRE - standard on Linux; on macOS use
# `brew install grep` and set SREDNOFF_GREP_BIN=ggrep, or run under WSL).

GREP_BIN="${SREDNOFF_GREP_BIN:-grep}"

# name|pattern pairs, one per line. Cross-checked against gitleaks.toml and Slack's own
# token format, 2026-07-01, same patterns as hook-lib.ps1 for cross-platform parity.
_SECRET_RULES='openai_api_key|sk-[A-Za-z0-9_-]{32,}
anthropic_api_key|sk-ant-[A-Za-z0-9_-]{20,}
github_token|gh[pousr]_[A-Za-z0-9_]{32,}
aws_access_key|AKIA[0-9A-Z]{16}
google_api_key|AIza[0-9A-Za-z_-]{35}
private_key|-----BEGIN (RSA |DSA |EC |OPENSSH |)?PRIVATE KEY-----
jwt|eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}
stripe_key|\b(sk|rk)_(test|live|prod)_[A-Za-z0-9]{10,99}
slack_token|xox[pbao]-[0-9]{10,13}-[0-9]{10,13}-[0-9]{10,13}-[a-f0-9]{32}
slack_webhook|hooks\.slack\.com/services/T[A-Za-z0-9]{8,}/B[A-Za-z0-9]{8,}/[A-Za-z0-9]{20,}
twilio_key|SK[0-9a-fA-F]{32}
sendgrid_key|SG\.[A-Za-z0-9=_.-]{60,}
npm_token|npm_[A-Za-z0-9]{36}'

# Content-based secret scan (not just filename heuristics). Prints one matched rule name
# per line (deduped by construction - each rule can only match/print once).
find_secret_signals() {
  local text="$1"
  [ -z "$text" ] && return 0
  local name pattern
  while IFS='|' read -r name pattern; do
    [ -z "$name" ] && continue
    if printf '%s' "$text" | "$GREP_BIN" -Pq "$pattern" 2>/dev/null; then
      printf '%s\n' "$name"
    fi
  done <<< "$_SECRET_RULES"
}

sha256_hex() {
  local text="$1"
  if command -v sha256sum >/dev/null 2>&1; then
    printf '%s' "$text" | sha256sum | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then
    printf '%s' "$text" | shasum -a 256 | awk '{print $1}'
  else
    printf ''
  fi
}

# Privacy-safe audit trail: logs ONLY when something is flagged (secret/dangerous pattern),
# not every tool call. Stores a sha256 of the raw hook input, never the input itself, so no
# secret content ever lands on disk here. Silently no-ops if jq is unavailable.
# session_id correlation (concept adapted from paperclipai/paperclip's run-ID audit trail,
# MIT - their pattern stamps every mutating API call with a run ID; ours stamps every hook
# decision with Claude Code's own session_id, present at the top level of every hook JSON
# payload per official docs). Lets you grep hook-events.jsonl for everything that happened
# within one specific session.
write_hook_ledger() {
  local hook_script="$1" decision="$2" raw_input="$3"; shift 3
  local findings=("$@")
  command -v jq >/dev/null 2>&1 || return 0
  local log_dir="$HOME/.claude/logs"
  mkdir -p "$log_dir" 2>/dev/null || return 0
  local ts input_hash findings_json session_id
  ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  input_hash=""
  [ -n "$raw_input" ] && input_hash="$(sha256_hex "$raw_input")"
  session_id="$(printf '%s' "$raw_input" | jq -r '.session_id // empty' 2>/dev/null || true)"
  if [ "${#findings[@]}" -gt 0 ]; then
    findings_json="$(printf '%s\n' "${findings[@]}" | jq -R . | jq -sc .)"
  else
    findings_json="[]"
  fi
  jq -nc \
    --arg ts "$ts" --arg hook "$hook_script" --arg decision "$decision" \
    --argjson findings "$findings_json" --arg hash "$input_hash" --arg session_id "$session_id" \
    '{ts: $ts, hook: $hook, decision: $decision, findings: $findings,
      session_id: (if $session_id == "" then null else $session_id end),
      input_sha256: (if $hash == "" then null else $hash end)}' \
    >> "$log_dir/hook-events.jsonl" 2>/dev/null || true
}
