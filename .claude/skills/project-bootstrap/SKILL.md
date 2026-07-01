---
name: project-bootstrap
description: Use this skill when starting work in a repository or when Claude MD OS files are missing. It initializes CLAUDE.md, .claude/rules, .claude/skills, .agent workflow files, and safety scripts without overwriting existing work.
---

# Project Bootstrap Skill

Use this skill when entering a new repository.

## Required files

- CLAUDE.md
- code_review.md
- .claude/rules/
- .claude/skills/
- .agent/
- scripts/init-claude-project.ps1 (Windows) / scripts/init-claude-project.sh (bash)

## Workflow

1. Check whether the required files exist.
2. If missing, initialize from `~/.claude/templates/claude-md-os`.
3. If existing, do not overwrite silently.
4. Create backups with timestamp.
5. Report created, updated, skipped, and backed up files.

## Command

Windows / PowerShell:

```powershell
& "$env:USERPROFILE\.claude\templates\claude-md-os\scripts\init-claude-project.ps1" .
```

bash:

```bash
~/.claude/templates/claude-md-os/scripts/init-claude-project.sh .
```
