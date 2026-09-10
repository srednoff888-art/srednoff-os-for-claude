# Security

SREDNOFF OS's hooks are a guardrail layer, not a replacement for platform permissions,
sandboxing, secret management, or human approval. Concept ported from srednoff-os (the
Codex sibling); this describes what's actually wired in this repository.

## Hook Posture

| Hook | Event | Purpose | Default effect |
|---|---|---|---|
| `block-dangerous-bash` | PreToolUse (Bash) | Blocks destructive commands (`rm -rf /`, `mkfs`, force-push, etc.) | deny |
| `protect-secrets` | PreToolUse (Write/Edit) | Blocks writing high-confidence secret patterns to disk | deny |
| `scan-prompt-secrets` | UserPromptSubmit | Blocks a prompt that pastes a high-confidence secret | block |
| `require-profile-lock-read` | PreToolUse (Edit/Write/MultiEdit) | Denies the first edit of a session in an OS-deployed project until `PROFILE.lock.md`/`CORE-300.md` has actually been read | deny, once per session |
| `mark-profile-lock-read` | PostToolUse (Read) | Companion to the above - records that the lock was read | n/a (bookkeeping) |
| `quality-reminder` | (see hooks/README.md) | Surfaces Principle #1 at relevant points | informational |

All hooks are **opt-in** - copying `.claude/settings.example.json` to
`.claude/settings.json` (or the Windows variant) is a deliberate step, since these hooks
can block tool calls. Nothing here changes a user's global Claude Code settings by
default.

## Path Rules: the Name Is Allowed, the Content Never Is

`protect-secrets` denies secret-*looking* file paths (`.env`, `id_rsa`, `*.pem`,
`credentials.json`, …). A number of names match that shape while being files you are
supposed to commit and edit, and denying them taught people to switch the hook off - the
worst possible outcome for a security control. These are allow-listed by name:

| Allowed name | Why it is not a secret |
|---|---|
| `.env.example` / `.sample` / `.template` / `.dist` (incl. `.env.local.example`, `.env.example.j2`) | Documents which variables a project needs. Was denied even for **Read**, so the agent could not discover what to configure |
| `*.pub` | The public half of a key pair - it belongs in `authorized_keys` and deploy keys |
| `ca-bundle.pem`, `fullchain.pem`, `chain.pem` | Public certificate chains, not private keys |
| `sealed-secrets.yaml`, `external-secrets.yaml`, `templates/secret.yaml` | Controller manifests that *reference* a secret held elsewhere - that is their entire purpose |
| `fake_/mock_/dummy_/test_/sample_credentials.json` | Test fixtures |

The allow-list covers the **name only**. For an allow-listed path the hook reads the file
from disk (capped at 256 KiB) and scans it with the same content rules, so a real key
committed into `.env.example` is still denied - including on `Read`, where there is no
tool payload to inspect. Verified both ways on both platforms: a template with
`postgres://user:password@db` passes, the same template carrying a real `AKIA…` key is
blocked.

`docs/deck.key` (a Keynote file) stays denied on purpose: `.key` is a private-key
extension far more often than a presentation. That is a known, accepted false positive,
pinned by a fixture rather than widened away.

Both the deny pattern and the allow-list live in `hook-lib.{sh,ps1}` so
`registry/evals/secret-path-fixtures.json` can test them. Before that they lived inside
the hook and had **no fixtures at all** - the reason the `.env.example` denial shipped and
survived: only the content rules were ever covered by the eval suite.

## Design: Fail-Open vs Fail-Closed

- `block-dangerous-bash`, `protect-secrets`, `scan-prompt-secrets` are **security
  controls** - ambiguity should lean toward blocking, though in practice they fail open
  on a missing `jq` dependency in the bash port (a known, flagged gap; `doctor` has a
  dedicated `jq-dependency` check specifically because of this).
- `require-profile-lock-read`/`mark-profile-lock-read` are **workflow-compliance
  nudges**, not security controls - they fail open by design (missing `session_id`,
  unreadable state, or a hook bug always results in ALLOW, never an unbreakable
  blocker). See `registry/CHANGELOG.md` v1.13 for the real case that motivated this pair:
  an agent that had every passive signal available (a banner in the first 6 lines of an
  always-loaded `CLAUDE.md`) still never read the lock file - passive context in an LLM's
  window is not enforcement; a hook that can literally deny a tool call is.

## Decision Contract

Claude Code hooks respond with `{"hookSpecificOutput": {"hookEventName": ..., "permissionDecision": "deny"|"ask"|"allow", "permissionDecisionReason": "..."}}`
for `PreToolUse`, or `{"decision": "block", "reason": "..."}` for `UserPromptSubmit`.
Verified against the official hooks documentation before implementation, not assumed -
see the contract notes in `registry/CHANGELOG.md` v1.13 for what was specifically checked
(top-level `session_id` presence, identical deny shape across Bash/Edit/Write/MultiEdit
matchers).

## Redacted Audit Trail

`hook-lib.ps1`/`.sh`'s `Write-HookLedger`/`write_hook_ledger` write to
`~/.claude/logs/hook-events.jsonl`: event type, decision, matched finding *names* (not
the raw secret value), an input hash, and (since v1.8) `session_id` for cross-session
correlation. Raw prompt/tool payloads are never logged - a safety log that leaked the
secrets it detected would defeat its own purpose.

## Provenance Gates (Rule 70)

External source intake is conservative by default:

- `INST`/`ANTH` catalog entries are pre-vetted (installed or official) - no gate.
- `WSH`/`VOLT`/`GH`/`FTB`/`EXT` entries are an unvetted discovery surface - github-research
  + license check required before adoption (never assumed safe because it's *in* the
  catalog).
- `SREDNOFF` entries (this project's own author, MIT, same license as this repo) skip the
  license-review step but not the general judgment of whether the skill fits - see
  `registry/INSTALL-SOURCES.md`.
- No copied prompt-leak text, no unreviewed MCP/CLI execution, no external package
  install without explicit confirmation.

## Private Boundary

The public repository (github.com/srednoff888-art/srednoff-os-for-claude) must never
contain: `.env` files, tokens/cookies/private keys/connector state, private client or
project data, machine-specific paths or credentials, private hook state. The
private-to-public release process (see [workflows.md](workflows.md)) redacts known
private project names via the source-of-truth rebuild - this has had real near-misses
(a manual sync once leaked a real business project name before a pre-push sweep caught
it) and is treated as a genuine, ongoing risk to actively guard, not a solved problem.

## Residual Risk

SREDNOFF OS reduces common, observed failure modes (secret pastes, destructive commands,
silently-skipped skill selection) but cannot prove every model action is safe. It's a
tested workflow layer with explicit, documented blind spots (see `QUALITY.md`'s "Known
Residual Risks"), not a formal security boundary.
