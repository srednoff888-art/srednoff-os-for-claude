#!/usr/bin/env bash
# Shared library for SREDNOFF OS bash hooks (Linux/macOS port of hook-lib.ps1).
# Source it: . "$(dirname "$0")/hook-lib.sh"
# Requires: jq (JSON in/out), grep -P (PCRE - standard on Linux; on macOS use
# `brew install grep` and set SREDNOFF_GREP_BIN=ggrep, or run under WSL).

GREP_BIN="${SREDNOFF_GREP_BIN:-grep}"

# --- PCRE availability (closes a silent fail-open) -----------------------------------
# Every PCRE call site pipes text into `grep -P`, sends stderr to /dev/null and treats a
# non-zero exit as "no match". But grep exits 2 on ERROR, not only 1 on no-match, and two
# separate errors were landing in exactly that blind spot - silently turning a security
# control off with no output and no warning:
#   1. A pattern starting with "-" is parsed by grep as an option. The private_key rule
#      starts with "-----BEGIN", so every call produced
#      `grep: unknown option -- ---BEGIN ...`, exit 2 => the private_key rule NEVER fired
#      in the bash port. A PEM private key was blocked on Windows and allowed on
#      Linux/macOS. Fixed by passing `--` before the pattern.
#   2. `grep -P` refuses to run under a locale it considers neither unibyte nor UTF-8
#      ("-P supports only unibyte and UTF-8 locales", exit 2). A hook inherits whatever
#      locale its caller had; observed with GNU grep 3.0 and an empty LANG, where even
#      LC_ALL=C was rejected. Every rule then reports "no match" and the hook allows
#      everything through.
# srednoff_grep_pcre() centralises both fixes and finally honours SREDNOFF_GREP_BIN at
# every call site (block-dangerous-bash.sh and protect-secrets.sh previously hardcoded
# `grep`, so the macOS `ggrep` workaround documented in README.md did not actually reach
# them). srednoff_pcre_ok() lets doctor report an unusable PCRE instead of leaving it
# invisible - same reasoning as the existing jq-dependency check.
_SREDNOFF_PCRE_LOCALE=""
_SREDNOFF_PCRE_OK=0
_srednoff_probe_pcre() {
  local loc
  # The empty entry means "keep the locale we already have" - a correctly configured
  # environment is never overridden; the fallbacks are tried only if it is rejected.
  # C.UTF-8 does not exist on macOS, en_US.UTF-8 does; C.utf8 is glibc's spelling.
  for loc in "" "C.UTF-8" "C.utf8" "en_US.UTF-8"; do
    if [ -z "$loc" ]; then
      if printf 'a' | "$GREP_BIN" -Pq -- 'a' 2>/dev/null; then
        _SREDNOFF_PCRE_OK=1; return 0
      fi
    elif printf 'a' | LC_ALL="$loc" "$GREP_BIN" -Pq -- 'a' 2>/dev/null; then
      _SREDNOFF_PCRE_LOCALE="$loc"; _SREDNOFF_PCRE_OK=1; return 0
    fi
  done
  return 1
}
_srednoff_probe_pcre || true

# Match the PCRE in $1 against text on stdin. Quiet; returns grep's own exit status.
srednoff_grep_pcre() {
  if [ -n "$_SREDNOFF_PCRE_LOCALE" ]; then
    LC_ALL="$_SREDNOFF_PCRE_LOCALE" "$GREP_BIN" -Pq -- "$1" 2>/dev/null
  else
    "$GREP_BIN" -Pq -- "$1" 2>/dev/null
  fi
}

# Success = PCRE is usable. doctor.sh turns a failure into a visible FAIL check.
srednoff_pcre_ok() { [ "$_SREDNOFF_PCRE_OK" -eq 1 ]; }

# Empty = the environment's own locale was fine and is left alone; otherwise the locale
# the probe had to pin to make grep -P run. Read this instead of the private variable.
srednoff_pcre_locale() { printf '%s' "$_SREDNOFF_PCRE_LOCALE"; }

# name|pattern pairs, one per line. Cross-checked against gitleaks.toml and Slack's own
# token format, 2026-07-01, same patterns as hook-lib.ps1 for cross-platform parity.
#
# Every fixed-prefix rule carries a left word boundary `(?<![A-Za-z0-9_-])`. Without it the
# prefix matched mid-word: the branch name `feature/disk-cleanup-and-cache-invalidation`
# contains "sk-cleanup-and-cache-invalidation" and was denied as an OpenAI key. Real keys
# are unaffected - they never appear glued to the end of another word.
#
# db_connection_string additionally refuses to fire on a password field that is obviously
# not a password: a shell/Jinja/Helm substitution ($VAR, ${VAR}, {{ .Values.x }}, %(x)s,
# <PASSWORD>, __PASS__) or a well-known placeholder word. Before this, a correctly written
# docker-compose.yml (`postgres://${DB_USER}:${DB_PASS}@db`) and every alembic.ini shipped
# with `postgresql://postgres:postgres@localhost` were denied - i.e. the rule fired on the
# safe form and taught people to turn the hook off. The driver suffix is also accepted now
# (`postgresql+psycopg2://`), which the old pattern missed entirely, so a REAL password
# behind a SQLAlchemy-style URL was never caught.
_SECRET_RULES='openai_api_key|(?<![A-Za-z0-9_-])sk-(proj-|svcacct-|admin-)?[A-Za-z0-9_-]{32,}
anthropic_api_key|(?<![A-Za-z0-9_-])sk-ant-[A-Za-z0-9_-]{20,}
github_token|(?<![A-Za-z0-9_-])gh[pousr]_[A-Za-z0-9_]{32,}
aws_access_key|(?<![A-Za-z0-9_-])AKIA[0-9A-Z]{16}
google_api_key|(?<![A-Za-z0-9_-])AIza[0-9A-Za-z_-]{35}
private_key|-----BEGIN (RSA |DSA |EC |OPENSSH |)?PRIVATE KEY-----
jwt|eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}
stripe_key|\b(sk|rk)_(test|live|prod)_[A-Za-z0-9]{10,99}
slack_token|xox[pbao]-[0-9]{10,13}-[0-9]{10,13}-[0-9]{10,13}-[a-f0-9]{32}
slack_webhook|hooks\.slack\.com/services/T[A-Za-z0-9]{8,}/B[A-Za-z0-9]{8,}/[A-Za-z0-9]{20,}
twilio_key|(?<![A-Za-z0-9_-])SK[0-9a-fA-F]{32}(?![0-9A-Za-z])
sendgrid_key|SG\.[A-Za-z0-9=_.-]{60,}
npm_token|(?<![A-Za-z0-9_-])npm_[A-Za-z0-9]{36}
gcp_service_account_key|"private_key_id"\s*:\s*"[a-f0-9]{40}"
db_connection_string|(postgres(ql)?(\+[a-z0-9_]+)?|mysql|mongodb(\+srv)?|redis|amqp):\/\/[^:\/\s"]+:(?!\$|\{\{|%\(|<|__)(?!(password|passwd|pass|changeme|change_me|secret|postgres|mysql|root|admin|example|placeholder|dummy|test|your_password|yourpassword)[@\/\s"])[^@\/\s"]+@'

# Content-based secret scan (not just filename heuristics). Prints one matched rule name
# per line (deduped by construction - each rule can only match/print once).
find_secret_signals() {
  local text="$1"
  [ -z "$text" ] && return 0
  local name pattern
  while IFS='|' read -r name pattern; do
    [ -z "$name" ] && continue
    if printf '%s' "$text" | srednoff_grep_pcre "$pattern"; then
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

# --- Secret-like FILE PATHS ---------------------------------------------------------
# Lives here, not inside protect-secrets.sh, so run-evals.sh can test these rules against
# fixtures. They had no fixtures at all before, which is exactly how the .env.example
# false positive shipped and survived: only the CONTENT rules were ever tested.
SECRET_PATH_PATTERN='(^|[\\/])\.env(\.|$)|id_rsa|id_ed25519|\.pem$|\.key$|secrets?\.(json|ya?ml|toml)$|credentials(\.json)?$'

# Names that match the pattern above but are meant to be committed and edited. Every one
# of these was a real, reproduced denial that blocked ordinary work:
#   .env.example / .sample / .template / .dist  - the file that documents which variables
#     a project needs. Denied even for Read, so the agent could not find out what to
#     configure. (The catalog already treats *.example as legitimate elsewhere:
#     `secrets?\.(json|ya?ml|toml)$` is anchored, so k8s/secrets.example.yaml was always
#     allowed - the .env branch was simply inconsistent with it.)
#   *.pub            - the PUBLIC half of a key pair; it belongs in authorized_keys and
#                      GitHub deploy keys. There is no secret in it by definition.
#   ca-bundle/fullchain/chain.pem - public certificate chains, not private keys.
#   sealed-secrets / external-secrets / secret-store manifests - these are CONTROLLER
#     configs that reference a secret held elsewhere; that is the entire point of them.
#   fake_/mock_/test_/sample_ credentials.json - test fixtures.
# The allow-list is about the NAME only. Content is still checked - see
# scan_path_content_on_disk below.
SECRET_PATH_ALLOW_PATTERN='(^|[\\/])\.env(\.[A-Za-z0-9_-]+)*\.(example|sample|template|tpl|tmpl|dist|defaults?)(\.(j2|jinja|tpl|tmpl))?$|\.pub$|(^|[\\/])(ca-bundle|ca-certificates|cacert|fullchain|chain)\.pem$|(^|[\\/])(sealed-secrets?|external-secrets?|secret-?stores?)[^\\/]*\.ya?ml$|(^|[\\/])templates[\\/]secrets?\.ya?ml$|(^|[\\/])[^\\/]*(fake|mock|dummy|sample|example|test)[-_][^\\/]*credentials(\.json)?$'

# Exit 0 = this path must be treated as a secret and denied.
is_secret_path() {
  local path="$1"
  [ -n "$path" ] || return 1
  printf '%s' "$path" | srednoff_grep_pcre "$SECRET_PATH_PATTERN" || return 1
  # Matched the deny pattern - unless it is one of the known-safe names.
  if printf '%s' "$path" | srednoff_grep_pcre "$SECRET_PATH_ALLOW_PATTERN"; then return 1; fi
  return 0
}

# Exit 0 = the name looked secret-like but is on the allow-list above.
is_secret_path_allowlisted() {
  local path="$1"
  [ -n "$path" ] || return 1
  printf '%s' "$path" | srednoff_grep_pcre "$SECRET_PATH_PATTERN" || return 1
  printf '%s' "$path" | srednoff_grep_pcre "$SECRET_PATH_ALLOW_PATTERN"
}

# We vouch for an allow-listed NAME, never for its CONTENT: a real key committed into
# .env.example is still a leak, and that is the one case the name-based allow-list would
# otherwise wave through - including on Read, where there is no tool_input to scan. So
# read the file itself (capped at 256 KiB, enough for any config template) and report any
# secret signals found. Prints one rule name per line, nothing if the file is clean or
# absent.
scan_path_content_on_disk() {
  local path="$1"
  [ -n "$path" ] && [ -f "$path" ] || return 0
  find_secret_signals "$(head -c 262144 "$path" 2>/dev/null)"
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
