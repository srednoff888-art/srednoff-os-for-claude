---
name: agent-instruction-migration
description: Use this skill to audit, deduplicate, and migrate coding-agent instructions across CLAUDE.md, CLAUDE.md, .clinerules, Cline rules, Roo custom modes, Continue rules, Cursor/Windsurf rules, OpenCode agents, prompt repositories, and Claude Code skills.
---

# Agent Instruction Migration

Convert useful agent rules into concise, maintainable Claude Code project instructions or skills without importing prompt spam.

## Workflow

1. Inventory sources: CLAUDE.md, CLAUDE.md, .clinerules, .roo, .continue, Cursor/Windsurf rules, OpenCode agents, MCP config, repo docs, and global skills.
2. Classify each rule as durable policy, project-specific convention, reusable workflow, tool integration, validation step, or low-value prompt text.
3. Keep project-local rules in CLAUDE.md when they describe repository structure, commands, boundaries, or coding style.
4. Promote reusable cross-project workflows into a skill only when they have clear triggers and repeated operational value.
5. Merge duplicates into the strongest existing instruction; do not create a new skill for a renamed copy.
6. Rewrite rules into imperative, testable instructions with explicit guardrails and validation commands.
7. Preserve provenance in the implementation notes or final report, not as copied source text inside the skill.
8. Regenerate skill index and validate all affected skills.

## Quality Filter

Accept a candidate when it:

- closes a real gap in installed skills or CLAUDE.md;
- adds a tool-specific workflow, validation method, or safety boundary;
- is supported by official docs, active OSS practice, or repeated local usage;
- can be described in a concise SKILL.md with clear triggers.

Reject a candidate when it:

- is generic "be helpful" or role-play text;
- duplicates an installed skill with weaker wording;
- relies on license-unclear copied prompt text;
- adds unsafe autonomy, hidden chain-of-thought demands, or secret exfiltration risk;
- cannot be validated with a command, checklist, or concrete task.

## Output Mapping

- Repository rules: CLAUDE.md.
- Reusable workflow: `.claude/skills/<skill>/SKILL.md`.
- Skill discoverability: `agents/openai.yaml`.
- Deterministic helper: skill-local `scripts/` or global `scripts/`.
- Long reference material: skill-local `references/`, loaded only when needed.

## Guardrails

- Do not overwrite existing instructions silently; create timestamped backups for material replacements.
- Do not copy large prompt files or copyrighted text verbatim.
- Do not migrate secrets, credentials, private endpoint names, or personal data.
- Do not preserve unsafe rules that bypass tests, approvals, rate limits, auth, or production safeguards.
