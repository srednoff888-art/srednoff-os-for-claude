# Validation

Every check listed here is re-runnable - none of these numbers are asserted without a
command that reproduces them. See `QUALITY.md` and `RELEASE.md` at the repo root for the
live evidence table (exact current counts); this page documents *what* each gate checks
and *where* it runs, which changes less often than the counts do.

## Local checks (`doctor.ps1`/`.sh`)

| Check | What it verifies |
|---|---|
| `status` | One-line loaded/OK summary |
| `structure` | All required OS files present in the project |
| `template-drift` | Project's `PROFILE.lock.md` OS-version stamp vs. the current template version (WARN only) |
| `registry-audit` | No duplicate catalog entries by name |
| `catalog-format` | Every `CORE-300.md` line parses per the documented record grammar |
| `catalog-json` | `CORE-300.json` (machine-readable export) is in sync with `CORE-300.md` |
| `skills-library` | Every `skills-library/*/SKILL.md` has a valid name/description/frontmatter |
| `version-control` | Registry + template auto-committed if dirty (a rollback point always exists) |
| `hook-canary` | Each active security hook, fed known-bad synthetic input, still denies/blocks |
| `profile-lock-gate` | `require-profile-lock-read`/`mark-profile-lock-read` deny→mark→allow cycle |
| `evals` | Full regression suite (mode/domain/selector/secret-pattern/quality-mode/source-ranker fixtures) |

## CI (GitHub Actions, `.github/workflows/ci.yml`)

| Job | Platform | What it proves |
|---|---|---|
| `shellcheck` | ubuntu | Every `.sh` file passes shellcheck (catches the exact bug class - `SC2068` unquoted array expansion - that once broke macOS bash 3.2 compat) |
| `json-validation` | ubuntu | Every manifest/eval/settings JSON file parses |
| `registry-and-evals` | ubuntu | Catalog format, registry audit, catalog-json drift gate, skills-library validation, full eval suite - the bash path |
| `hook-canary` | ubuntu | Security hooks deny/block known-bad input - independent of doctor's own copy of this check |
| `profile-lock-gate` | ubuntu | Same deny→mark→allow cycle as doctor, run fresh in CI |
| `bash-3-2` | Docker `bash:3.2` container | The exact shell macOS ships (`/bin/bash` 3.2.57, frozen at GPLv2) - not a proxy, the real binary |
| `windows-powershell` | `windows-latest` (PowerShell 5.1, not pwsh 7) | PS parse check, PSScriptAnalyzer (error severity), the full catalog/audit/skills-library/eval suite, hook canary, and the profile-lock gate - all on the flagship "zero-dependency" platform |

## Native plugin validator

`claude plugin validate --strict` against `.claude-plugin/plugin.json` and
`marketplace.json` - the actual Anthropic CLI validator, run for real rather than
inferred from reading the schema docs (this caught a real missing-`description`-field bug
in an earlier release; see `registry/CHANGELOG.md` v1.12).

## What "green" means here

A checkpoint is not reported as done until:

1. The relevant local `doctor` run is green (or shows only the known, expected,
   pre-existing WARN for the template root not being a deployable "project").
2. The public push's real GitHub Actions run - not a local re-run of the same
   scripts - shows every job green, checked via `gh run view`, not assumed from a local
   pass.

This project has caught real CI-only failures this way more than once (a Windows-specific
PowerShell argument-passing bug, a bash-3.2-only `mapfile`/unbound-array regression) that
never reproduced in local testing - "it works on my machine" is explicitly not the bar.
