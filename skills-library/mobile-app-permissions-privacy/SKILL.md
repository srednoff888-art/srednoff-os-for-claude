---
name: mobile-app-permissions-privacy
description: "Use this skill for mobile permissions, privacy labels, data collection, consent, OS permission prompts. Trigger when the task involves apps work related to Mobile App Permissions Privacy, production implementation, audits, debugging, strategy, or validation."
---

# Mobile App Permissions Privacy

Use this skill to handle Apps tasks focused on mobile permissions, privacy labels, data collection, consent, OS permission prompts.

## Workflow

1. Clarify the user outcome, constraints, current stack, and definition of done.
2. Inspect the local repository or provided artifacts before proposing changes.
3. Check official documentation when APIs, platform rules, SDK versions, policies, or production behavior may have changed.
4. For non-trivial choices, compare proven open-source patterns or examples and adapt ideas without copying incompatible code.
5. Implement the smallest production-ready change that satisfies the request.
6. Validate with the most relevant checks: tests, lint, typecheck, build, browser/device review, audits, or manual scenario.
7. Report changed files, commands run, remaining risks, and exact next steps.

## Focus Checklist

- Define scope and assumptions explicitly.
- Prefer existing project conventions and tools.
- Handle loading, empty, error, permission, and edge states where relevant.
- Include security, privacy, performance, accessibility, and rollback considerations when they apply.
- Keep output actionable and evidence-backed.

## Guardrails

- Do not request permissions before explaining user value.
- Do not perform destructive, paid, production, trading, publishing, or account-changing actions without explicit user confirmation.
- Do not expose secrets, private keys, tokens, cookies, personal data, or confidential business data.
- If validation is impossible, state exactly why and provide a manual verification path.
