---
name: github-research
description: Use this skill before architecture, dependency, integration, parser, bot, UI, deployment, MCP, Claude hooks, Claude skills, or non-trivial bugfix tasks. It forces Claude to search GitHub, compare open-source solutions, check licenses, and extract reusable patterns without copying unsafe code.
---

# GitHub Research Skill

Use this skill when the task needs external engineering precedent.

## Workflow

1. Identify the exact technical problem.
2. Generate 5-10 GitHub search queries.
3. Find at least 5 relevant repositories/examples/issues, if available.
4. Compare stars, recency, license, stack, tests, README quality, issues/PR health and architecture quality.
5. Extract reusable patterns.
6. Reject unsafe, stale, incompatible or unlicensed patterns.
7. Produce a concise decision.

## Output

```md
## GitHub Research

Search intent:
-

Repos checked:

| Repo | Relevance | Useful pattern | Risk |
|---|---|---|---|
|  |  |  |  |

Decision:
- Adopt:
- Adapt:
- Avoid:
- Build ourselves:

Implementation impact:
-
```

Never copy code unless the license is compatible and the user/project can legally use it.
