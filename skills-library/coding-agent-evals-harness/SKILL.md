---
name: coding-agent-evals-harness
description: Use this skill when designing or reviewing evaluations for coding agents, Claude Code workflows, SWE-bench-style tasks, repository repair benchmarks, tool-use regressions, planner/executor/reviewer loops, autonomy limits, or agent quality gates before rollout.
---

# Coding Agent Evals Harness

Evaluate coding agents with reproducible repository tasks, not isolated prompt examples.

## Workflow

1. Define the agent behavior under test: bugfix, feature build, refactor, review, migration, dependency update, CI triage, browser QA, or tool integration.
2. Build a task set from real issues or seeded fixtures with starting commit, instructions, allowed tools, time budget, and expected observable outcome.
3. Add oracle checks: unit/integration tests, golden files, lint/typecheck/build, snapshot/visual checks, static assertions, and manual review rubrics for judgment-heavy tasks.
4. Capture agent traces: plan, file reads, edits, commands, failures, retries, tool calls, final answer, elapsed time, cost, and diff.
5. Score on pass/fail first, then secondary metrics: minimality, maintainability, security, test quality, user-instruction adherence, and recovery from tool failures.
6. Include adversarial cases: misleading issue text, flaky tests, missing docs, irrelevant files, untrusted content, stale dependencies, and permission-denied tools.
7. Compare against a baseline agent/model/config before changing prompts, skills, tools, or autonomy settings.
8. Store eval cases, prompts, harness version, model config, and expected results together so regressions are explainable.

## Checklist

- Use small local smoke evals for every skill/prompt change and deeper benchmark suites for agent architecture changes.
- Separate deterministic checks from reviewer judgment; do not hide failing tests behind a qualitative score.
- Prevent benchmark leakage: agents should see the task, repo, and allowed docs, not the expected patch.
- Track invalid runs separately from failed runs when the environment, dependency install, or external service is unavailable.
- Review diffs for unsafe changes even when tests pass.
- Keep tasks representative of Ivan's actual work, not only public benchmark distributions.

## Guardrails

- Do not treat SWE-bench or any single leaderboard as proof that a workflow is production-ready.
- Do not run evals against private repositories in third-party services without approval and data-safety review.
- Do not include secrets, private customer data, production credentials, or proprietary issue text in reusable eval fixtures.
- For security, hiring, legal, medical, financial, or trading tasks, require human review as part of the scoring rubric.
