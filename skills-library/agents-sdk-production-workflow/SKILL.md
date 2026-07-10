---
name: agents-sdk-production-workflow
description: Use this skill when designing, reviewing, debugging, or productionizing OpenAI Agents SDK, Responses API, or similar agent systems with tools, handoffs, guardrails, tracing, evals, human approval, retries, and deployment safety.
---

# Agents SDK Production Workflow

Build agent systems as explicit workflows with observable state, typed boundaries, and human review for risky actions.

## Workflow

1. Define the user outcome, risk level, and allowed autonomous actions.
2. Choose orchestration shape: single agent, deterministic pipeline, supervisor, handoff graph, or planner/executor/reviewer.
3. Define every tool contract with typed inputs, least privilege, timeouts, idempotency, and redacted logs.
4. Add guardrails before irreversible actions: input validation, output schema checks, policy checks, confirmation gates, and rate limits.
5. Add tracing around model calls, tool calls, handoffs, retries, errors, cost, latency, and user-visible decisions.
6. Build evals from real tasks: golden cases, adversarial cases, tool failure cases, and regression thresholds.
7. Add fallback behavior: no-op, partial result, queue for human review, or deterministic implementation.
8. Validate locally with mocked tools before touching live APIs, billing, production data, emails, trades, or deployments.

## Design Checklist

- Prefer deterministic code for parsing, routing, validation, and data transforms.
- Keep model prompts small and task-specific; move durable policy into code or skills.
- Use structured outputs for decisions that drive tools or persistence.
- Separate planner, executor, verifier, and user-communication responsibilities when a task spans multiple steps.
- Treat handoffs as typed state transitions, not vague "ask another agent" prompts.
- Store only necessary traces; redact secrets, tokens, cookies, PII, and regulated data.
- Add budget caps for tokens, wall time, retries, tool calls, and paid API actions.
- Version prompts, tool schemas, eval datasets, and production config together.

## Review Questions

- What can the agent do without human approval?
- What happens when a tool returns stale, partial, malicious, or malformed data?
- Which actions are irreversible or expensive?
- Which eval would fail if the next model release changes behavior?
- Can a production incident be reconstructed from traces without exposing secrets?

## Guardrails

- Do not let an LLM decide legal, medical, financial, hiring, trading, security, or compliance outcomes without human review.
- Do not grant broad filesystem, network, database, email, deployment, billing, or admin tools when narrow tools are enough.
- Do not log raw prompts or tool payloads when they may contain secrets or personal data.
- Do not deploy an agent workflow without tests for tool failures, prompt injection, and schema violations.
