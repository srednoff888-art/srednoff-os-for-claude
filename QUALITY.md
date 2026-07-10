# SREDNOFF OS Quality Status

This file documents what is currently verified and what is intentionally not promised.
Every row below is a command anyone can re-run against this repo - no number here is
asserted without a command that produces it.

Last verified: 2026-07-10 (v1.14).

## Current Status

| Check | Result | Command |
|---|---:|---|
| Doctor structure check | PASS | `scripts/doctor.ps1 -ProjectPath . -RunEvals` |
| Registry audit (duplicate names) | PASS, 2027 records, 0 duplicates | `registry/audit-registry.ps1` |
| Catalog format validator | PASS, 2027 parsed, 0 issues | `registry/validate-catalog-format.ps1` |
| Eval suite (mode/domain/selector/invariant) | PASS, 33/33 | `scripts/run-evals.ps1` (or `.sh`) |
| Security hook canary (block-dangerous-bash, protect-secrets, scan-prompt-secrets) | PASS, 3/3 | `doctor.ps1`'s built-in canary, or CI job `hook-canary` |
| PROFILE.lock enforcement gate (deny -> mark -> allow cycle) | PASS | CI job `profile-lock-gate` |
| bash 3.2 compatibility (real `bash:3.2` container, matches macOS `/bin/bash`) | PASS | CI job `bash-3-2` |
| Windows PowerShell 5.1 (hooks, routing, full eval suite) | PASS | CI job `windows-powershell` |
| ShellCheck (all `.sh`, `--severity=warning`, `SC1090` excluded by design) | PASS, 0 issues | CI job `shellcheck` |
| JSON validation (all manifests/evals/settings) | PASS | CI job `json-validation` |
| Official plugin manifest validator | PASS | `claude plugin validate --strict .` |
| GitHub Actions CI | PASS, 7/7 jobs on every push | [`.github/workflows/ci.yml`](.github/workflows/ci.yml) |

## What Changed Recently

See [`registry/CHANGELOG.md`](registry/CHANGELOG.md) for the full version history. Highlights:
the PROFILE.lock enforcement gate (v1.13) exists because an embedded `CLAUDE.md` banner alone
was proven, in a real project, not to cause an agent to actually read the skill selection -
passive context in a prompt is not enforcement in Claude Code; only a hook that can deny a
tool call is. The SessionStart banner (v1.14) was tightened after research confirmed Claude
Desktop's Code tab shares hooks/CLAUDE.md/settings with the CLI but has no `statusLine` or
footer-badge equivalent, so inventing one there would have been fragile and misleading.

## What This Does Not Promise

- It does not make Claude obey instructions with mathematical certainty. Hooks are the one
  mechanism that can actually deny a tool call; everything else (rules, `CLAUDE.md`, skills)
  is context the model can still fail to act on.
- It does not replace platform-level permissions, sandboxing, secret managers, or human review.
- It does not prove all 2027 registry records are individually optimal. ~569 of them
  (WSH/VOLT/FTB/GH-sourced) are an unvetted discovery surface, not license-cleared
  endorsements - see rule `70-skills-registry.md`'s verification gate before adopting one.
- It does not guarantee every rule or skill improves every project; the selector produces a
  starting shortlist, not a final answer.

## Known Residual Risks

- Fail-open hooks (`require-profile-lock-read`, `mark-profile-lock-read`) are a compliance
  nudge, not a security control, by design - a bug there results in silent allow, not a
  blocked session. `block-dangerous-bash`/`protect-secrets`/`scan-prompt-secrets` are meant
  to fail closed but currently degrade to fail-open if `jq` is missing on Linux/macOS - a
  known, documented gap, not a silent one.
- The selector still relies on handcrafted tag matching and fixtures; it has not been
  benchmarked against a hidden-oracle harness (a Codex-sibling project of this same author
  has one - see `registry/PLAN-V2-MERGE-FROM-CODEX.md` Phase 4.1 for the plan to adapt it).
- Public forks can become unsafe if a user adds their own `.env`, real project paths, or
  tokens into the shared template layer instead of a project-local overlay.
- `statusLine`/footer visibility depends on terminal support (OSC 8, ANSI) and is opt-in;
  it is not a guarantee the user will notice the system is active without also reading the
  SessionStart banner text.

## Release Gate

A change ships when: `doctor.ps1`/`doctor.sh` report OK on both platforms, `run-evals`
reports the current full pass count on both platforms, the hook canary passes on both,
`claude plugin validate --strict` passes, and all GitHub Actions jobs are green on the
actual push (not just locally reproduced).
