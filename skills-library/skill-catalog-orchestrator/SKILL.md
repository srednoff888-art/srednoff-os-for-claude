---
name: skill-catalog-orchestrator
description: Use this skill when selecting, combining, auditing, or routing across a large Claude Code skill catalog, agent profiles, subagents, plugins, MCP tools, or project CLAUDE.md instructions for complex multi-domain work.
---

# Skill Catalog Orchestrator

Route complex work through the smallest useful set of skills and agents, then verify that the selected instructions actually cover the task.

## Routing Workflow

1. Restate the concrete outcome, risk level, and definition of done.
2. Search the skill index by exact domain terms, tools, frameworks, and failure modes.
3. Select the minimal skill set that covers the work; prefer specific skills over broad agent profiles.
4. Read each selected SKILL.md completely before acting; load references only when the skill says they are relevant.
5. Sequence skills by dependency: research, architecture, implementation, validation, review, deployment.
6. Assign subagents only when independent review, parallel research, or specialized validation will improve quality.
7. Resolve conflicts by following project CLAUDE.md first, then user instructions, then the most specific skill, then general policy.
8. After the task, note any missing skill, stale trigger, overlap, or validation gap for catalog maintenance.

## Selection Rules

- Use one skill when the task is narrow.
- Use two or three skills when the task spans implementation plus validation or domain plus platform.
- Avoid loading broad agent profiles when a precise workflow skill exists.
- Avoid combining skills that duplicate the same checklist unless one adds a concrete tool or guardrail.
- Prefer official docs and active repo patterns for fast-moving integrations.
- Use review/security/compliance skills for high-impact domains even when the implementation looks small.

## Catalog Health Checks

- Missing trigger: a useful skill exists but would not be invoked by the user's wording.
- Duplicate trigger: two skills describe the same action without different scope.
- Weak skill: generic advice, no checklist, no validation, no guardrails.
- Stale skill: references old APIs, deprecated tools, or outdated workflow assumptions.
- Overbroad skill: claims a domain but gives no execution path.

## Output

```md
Skill routing:
- Selected:
- Skipped:
- Order:
- Validation:
- Catalog notes:
```
