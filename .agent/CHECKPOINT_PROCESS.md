# CHECKPOINT_PROCESS.md — multi-stage initiative tracking

> Complements [PLANS.md](PLANS.md): PLANS.md is the ExecPlan template for a *single* task.
> This file is for when an initiative is bigger than one task/session - several distinct
> stages, each independently shippable, spanning multiple sessions. Concept ported from
> srednoff-os (the Codex sibling)'s checkpoint-table pattern; adapted from a real worked
> example already run in this project (see below), not written speculatively.

## When to use a checkpoint table instead of a single ExecPlan

- The work naturally splits into stages that each produce a shippable, testable result
  on their own (not just intermediate scaffolding for a later stage).
- The initiative is expected to span multiple sessions, and picking it back up cold
  needs a clear "what's done, what's next" record that survives a context reset.
- Each stage should get independent user sign-off before the next one starts - a
  checkpoint table makes that gate visible instead of implicit.

## Execution Rule

1. Write the full stage breakdown up front, even if later stages get refined - a
   plan the user can react to and redirect beats silently discovering scope mid-work.
2. Work on one stage at a time. Do not start stage N+1 until stage N is committed,
   pushed, and verified green in real CI (not just locally).
3. Every stage ends with: doctor/evals regression on all supported platforms, a
   CHANGELOG.md + version.json entry, a commit, a push, and a real CI check via
   `gh run view` - not assumed from a local pass.
4. Report each stage's completion with a clear summary (what shipped, what broke and
   got fixed, what's next) and get explicit go-ahead before continuing, unless the user
   has already blanket-authorized the whole sequence.
5. If a stage's actual scope turns out to differ from the plan once you're inside it
   (a wrong assumption, a discovery that changes what's needed), say so plainly and
   explain the revised scope - don't silently narrow or pad the work to match the
   original estimate.
6. Update the plan file itself (or a changelog within it) as stages complete, so a
   fresh session picking this up has an accurate record, not just the original intent.

## Table Template

```md
## Stage Table

| Stage | Scope | Required output | Status |
|---:|---|---|---|
| 1 | ... | ... | Not started / In progress / Done |
| 2 | ... | ... | ... |
```

## Worked example in this repository

`registry/PLAN-V2-MERGE-FROM-CODEX.md` - a 3-stage plan to selectively merge value from
srednoff-os (the Codex sibling) into this repository, actually executed end to end:

- **Stage 1** (v1.15): quality modes, PowerShell static analysis in CI, evidence docs,
  native rule path-scoping.
- **Stage 2** (v1.16): source-ranker + design-source-registry, `apply-os-all -Sync`,
  catalog-json export (including reviewing and merging a real external contributor PR),
  and a critical safety bug found and fixed along the way (an unbounded git-root walk
  that briefly deployed the OS into the user's home directory during testing).
- **Stage 3** (v1.17): a planned "308-skill import" that turned out, on investigation,
  to already be 306/308 done as catalog stubs from an earlier pass - the actual scope
  became backfilling descriptions and building installable content, a materially
  different (and smaller) task than originally planned, reported as such rather than
  forced to match the original framing.

Each stage: real doctor/eval regression on both platforms, a CHANGELOG entry, a private
commit, a redacted public push, and a real GitHub Actions run confirmed green via
`gh run view` before the next stage started.
