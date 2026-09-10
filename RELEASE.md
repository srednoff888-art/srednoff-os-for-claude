# SREDNOFF OS - Release Note

Current public release: **v1.20** (2026-07-27) - see `registry/version.json`, which is the
source of truth for the version and the record counts.

## Release Item Status

| Item | Status |
|---|---|
| Public package | Published on GitHub: [srednoff-os-for-claude](https://github.com/srednoff888-art/srednoff-os-for-claude) |
| Claude Code plugin path | `/plugin marketplace add srednoff888-art/srednoff-os-for-claude` then `/plugin install srednoff-os` (`defaultEnabled: false` - opt-in) |
| GitHub Actions CI | 7/7 jobs passing on Windows and Ubuntu on the current `main` |
| PROFILE.lock enforcement gate | Shipped v1.13 - closes the "passive banner does not equal compliance" gap found in a real project |
| SessionStart banner | Tightened to a single scannable line in v1.14 after Claude Desktop UI research found no `statusLine`/footer-badge equivalent there |
| Cross-platform parity | Full PowerShell 5.1 / bash 3.2+ parity, verified against a real `bash:3.2` container in CI (matches macOS's stock `/bin/bash`) |

See [`QUALITY.md`](QUALITY.md) for the full verified-check table and [`registry/CHANGELOG.md`](registry/CHANGELOG.md) for the version history.

## What's Next

[`registry/PLAN-V2-MERGE-FROM-CODEX.md`](registry/PLAN-V2-MERGE-FROM-CODEX.md) - selectively
merging process/metadata improvements (quality modes, a design-source registry, curated skill
imports, profiles, an MCP trust inventory, a donor-research manifest) from `srednoff-os`, the
same author's sibling project for Codex CLI, while keeping this repo's stronger enforcement
mechanisms (real deny-capable hooks, full bash 3.2 parity, plugin packaging, a hand-curated
2000+-record registry with provenance) as the baseline - **completed in v1.18**. See
[`registry/CHANGELOG.md`](registry/CHANGELOG.md) for what landed in v1.15-v1.20.

## Not Yet Promised

- The benchmark harness in [`benchmarks/`](benchmarks/) (control arm vs. OS arm, hidden
  oracles) shipped in v1.18, but **no end-to-end run has been executed** - a real run spends
  API budget across `tasks x arms x repeats` and is deliberately not part of CI. The oracle
  scoring, security scan and OS-arm deployment were smoke-tested in isolation; the actual
  `claude -p` invocation path has not been exercised. So there are still no published
  control-vs-OS numbers, only a reproducible way to produce them.
