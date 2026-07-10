---
name: codex-subagent-orchestration
description: Use this skill to design, audit, or implement bounded Claude Code subagent and custom-agent workflows, reviewer passes, multi-agent research, and specialist agent profiles with clear responsibilities, context contracts, token budgets, and safety gates.
---

# Claude Code Subagent Orchestration

Use subagents only when they produce a concrete quality gain: independent review, parallel research, specialist analysis, or bounded implementation.

## Workflow

1. Define the outcome, risk level, decision owner, and whether subagents are needed at all.
2. Split work by responsibility, not by vague persona. Prefer narrow roles such as explorer, reviewer, security reviewer, visual QA, or migration planner.
3. Give each subagent a context contract: artifact paths, source URLs, exact question, expected output, forbidden assumptions, and validation command.
4. Limit tools, filesystem access, network access, sandbox mode, and production scope to the smallest useful surface.
5. Set token, time, depth, and concurrency limits before spawning work.
6. Require every subagent to separate facts, assumptions, risks, and recommended actions.
7. Merge outputs in the parent thread; do not let subagents make irreversible, paid, production, email, billing, DNS, trading, legal, medical, hiring, or compliance decisions.
8. Add regression coverage when the workflow will be reused: eval fixture, checklist, prompt contract, or automation memory entry.

## Custom Agent Checklist

- `name` is stable, short, and matches the job.
- `description` states when to use the agent and when not to.
- `developer_instructions` define responsibilities, output format, evidence standard, and escalation rules.
- Optional `nickname_candidates` are presentation-only.
- Optional model, reasoning, sandbox, MCP, and skills settings are narrower than the parent session unless there is a documented reason.
- The agent cannot recursively delegate unless recursion is explicitly required and capped.

## Useful Patterns

- Explorer plus reviewer for unfamiliar repositories.
- Parallel source researchers for GitHub/docs comparison.
- Security or privacy reviewer for high-impact changes.
- Visual QA reviewer after frontend implementation.
- Migration planner plus test architect for risky refactors.

## Output Shape

Return:

- subagent map with purpose and inputs;
- tool and sandbox limits;
- merge protocol;
- validation gates;
- rejected agent roles and why.

## Guardrails

- Do not spawn agents to avoid reading the source yourself.
- Do not leak secrets, raw private logs, credentials, or personal data into prompts.
- Do not use broad "do everything" agents.
- Do not trust subagent findings without parent verification against source artifacts.
