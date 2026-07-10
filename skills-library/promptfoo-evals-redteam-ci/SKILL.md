---
name: promptfoo-evals-redteam-ci
description: Use this skill when building, reviewing, or debugging Promptfoo-based LLM, agent, RAG evals, red-team scans, provider setup, or GitHub Actions CI gates; do not use when ordinary deterministic unit tests are enough.
---

# Promptfoo Evals Redteam CI

Use this skill to keep Promptfoo workflows reproducible, private by default, and cheap enough to run in CI.

## Workflow

1. Define the target, risk level, eval owner, required providers, expected outputs, and pass/fail thresholds.
2. Prefer deterministic assertions first: JSON validity, exact contains, schema checks, regex, JavaScript/Python assertions, and only then LLM-as-judge rubrics.
3. Keep cases in reusable `file://tests/*.yaml` or provider files instead of dumping large inline configs.
4. For Promptfoo config values, use the tool's supported templating form for environment variables and never print secrets in logs.
5. When an LLM rubric is necessary, inline the source text or facts the grader must compare against; do not rely on vague references like "the article".
6. For provider setup, wrap HTTP, JavaScript, or Python targets with timeouts, redacted errors, stable fixtures, and no production side effects.
7. For red-team scans, scope categories, rate limits, budget, target environment, and human-review triage before running against live endpoints.
8. For GitHub Actions, trigger only on relevant prompt/eval/provider paths, cache safely, use least-privilege permissions, and fail the PR only on agreed thresholds.
9. Triage failures into regression, flaky judge, bad fixture, provider error, security issue, or acceptable behavior change.

## Checklist

- Eval data contains no secrets, cookies, credentials, private customer data, or unnecessary personal data.
- Assertions are as deterministic as practical before paid/model-graded checks.
- Config, provider wrappers, prompts, thresholds, and model versions are committed together.
- CI path filters, cache, permissions, and artifact retention are explicit.
- Red-team results require human review before product, legal, security, hiring, medical, financial, or compliance decisions.

## Guardrails

- Do not run scans against production, paid APIs, private endpoints, or third-party systems without explicit approval.
- Do not use Promptfoo or LLM judges as the only gate for legal, medical, financial, hiring, trading, security, or compliance outcomes.
- Do not upload proprietary prompts, logs, traces, or eval data to external viewers without approval.
- Do not hide model cost, latency, or false-positive risk from the release decision.
