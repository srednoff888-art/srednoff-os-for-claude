---
name: record-replay-skill-miner
description: Use this skill to turn repeated Claude Code workflows, manual demonstrations, Record & Replay captures, trace snippets, runbooks, or recurring automation steps into concise reusable skills, eval fixtures, scripts, hooks, or checklist updates without leaking secrets or bloating context.
---

# Record Replay Skill Miner

Use this skill when a task has been repeated enough that it should become durable Srednoff OS capability.

## Workflow

1. Define the repeated job, trigger phrase, expected output, and definition of done.
2. Collect only the minimum evidence needed: Record & Replay notes, command transcript, diff, runbook, issue, PR, or automation memory.
3. Scrub secrets, tokens, cookies, private keys, personal data, paid-account details, and production identifiers before extracting patterns.
4. Separate stable procedure from one-off project details.
5. Choose the smallest durable surface:
   - `CLAUDE.md` for project policy.
   - `SKILL.md` for reusable workflow.
   - `scripts/` for deterministic fragile steps.
   - `evals/` for regression fixtures.
   - hooks for opt-in enforcement.
   - automation memory for recurring task continuity.
6. Draft the skill with `name` and `description` only in frontmatter, a concise imperative workflow, checklist, and guardrails.
7. Add or refresh `agents/openai.yaml` when the skill should be discoverable in the app.
8. Add a validation path: prompt trigger check, quick skill validation, selector eval, script test, or manual replay scenario.
9. Reject the conversion if the workflow is still vague, low frequency, duplicate, unsafe, license-risky, or too project-specific.

## Skill Quality Checklist

- Name is lowercase hyphen-case and under 64 characters.
- Description front-loads exactly when to use and not use the skill.
- Body is shorter than the repeated workflow it replaces.
- Scripts are included only when deterministic execution beats instructions.
- References are linked only when the details are too large for `SKILL.md`.
- Guardrails cover destructive, paid, production, security, legal, medical, financial, hiring, and privacy-sensitive actions when relevant.
- Validation is explicit enough for the next automation run to catch drift.

## Output Shape

Return:

- proposed durable surface;
- skill or eval name;
- source evidence used;
- what was generalized;
- what was intentionally excluded;
- validation command or replay scenario.

## Guardrails

- Do not store raw prompts, secrets, private logs, customer data, or full proprietary traces in a skill.
- Do not copy third-party workflow text or code without license review.
- Do not create broad prompt-spam skills; merge with an existing narrower skill when overlap is high.
- Do not add hooks that perform destructive or externally visible actions.
