# SREDNOFF OS Documentation

Deeper reference for the engineering-discipline overlay summarized in the top-level
[README.md](../README.md). Concept ported from srednoff-os (the Codex sibling)'s docs
portal; content rewritten to describe what this repository actually contains and does.

## Navigation

| Document | Purpose |
|---|---|
| [Architecture](architecture.md) | System map, file ownership, startup flow, selection flow, release evidence path |
| [Security](security.md) | Hook posture, decision contract, redacted audit trail, provenance gates |
| [Workflows](workflows.md) | Daily project workflow, sync/refresh, release checkpoint, TURBO boundaries |
| [Validation](validation.md) | Local and CI gates, doctor checks, evidence table |

## Documentation Principles

- Every claim here is backed by a file, script, or CI job that actually exists at the
  time it's written - not aspirational. If a fact drifts (a check gets renamed, a job
  count changes), the doc is wrong until fixed, same as a broken test.
- Keep the always-loaded layer (`CLAUDE.md`, `.claude/rules/`) compact and link out to
  these deeper references rather than inlining everything.
- External sources stay unvetted until provenance and license checks pass (rule 70).
- Treat docs as release evidence: update them in the same commit as the behavior change,
  not as a follow-up.
