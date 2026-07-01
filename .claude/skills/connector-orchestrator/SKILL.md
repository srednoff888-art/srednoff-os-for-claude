---
name: connector-orchestrator
description: Use this skill when a task may benefit from MCP servers or connected tools such as GitHub, Vercel, Supabase, Figma, Canva, Gmail, Calendar, Contacts, Replit, Convex, Anthropic, or OpenAI.
---

# Connector Orchestrator Skill

Use MCP/connectors only when they provide facts or actions that improve the result.

## Workflow

1. Identify which external systems matter.
2. Check whether relevant MCP/connectors are available.
3. Use the minimum necessary data.
4. Ask confirmation before destructive actions.
5. Verify the result after actions.
6. Report what was used and why.

## Destructive actions requiring explicit approval

- deleting production data;
- disabling RLS/auth/security;
- changing production env vars;
- deploying to production;
- changing billing/domain/DNS/payment settings;
- sending emails;
- merging PRs;
- force-pushing;
- running irreversible migrations.

## Output

```md
## Connector Plan

Needed connectors:
-

Why:
-

Actions:
-

Requires confirmation:
-
```
