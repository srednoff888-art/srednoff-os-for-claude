---
description: Initialize Claude MD OS files in the current project.
---

Use the project-bootstrap skill.

Initialize Claude MD OS in the current repository.

Windows / PowerShell:

```powershell
& "$env:USERPROFILE\.claude\templates\claude-md-os\scripts\init-claude-project.ps1" .
```

bash:

```bash
~/.claude/templates/claude-md-os/scripts/init-claude-project.sh .
```

Do not overwrite existing files without timestamped backups. After initialization, list created, updated, skipped and backed up files.
