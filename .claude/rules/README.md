# .claude/rules/

Ten numbered files, always loaded every session (`00`-`90`), read as a set, not as
separate opt-in modules:

| File | Covers |
|---|---|
| `00-operating-system.md` | Principle #1, top-level operating stance |
| `10-github-research.md` | When/how to research GitHub before adopting external code |
| `20-connectors.md` | Connector/MCP usage stance |
| `30-user-briefing.md` | How to read and confirm task intent |
| `40-quality-gate.md` | Validation expectations before calling work done |
| `50-security.md` | Secret/destructive-action handling, swarm confirmation |
| `60-exec-plans.md` | Plan structure, failure-lifecycle for delegated work |
| `70-skills-registry.md` | PROFILE.lock, CORE-300 selection, quality modes, verification gate |
| `80-model-routing.md` | Haiku/Sonnet/Opus routing by required quality |
| `90-subagent-contract.md` | Final-disposition contract for delegated Agent/Task calls |

None of these ten carry a `paths:` frontmatter field. That is deliberate: they are
cross-cutting (security, model routing, skill selection) and must stay active regardless
of which file is being touched.

## Path-scoped rules (native Claude Code feature)

`.claude/rules/*.md` files support an optional YAML frontmatter `paths:` field with glob
patterns. A rule with `paths:` only loads into context when Claude is working with a file
matching one of those globs - useful for a project-specific convention that would be noise
everywhere else in the repo.

```markdown
---
paths:
  - "src/api/**"
---

# API handler conventions

All handlers in this directory must validate input with Zod before doing anything else.
```

Add project-specific scoped rules as additional numbered (or unnumbered) files in this
same directory - `init-claude-project.ps1`/`.sh` will not overwrite files it did not create.
Keep the shared core (`00`-`90` above) path-agnostic; scope only the rules you add on top
of them for a specific project's directory structure.
