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

The script is create-only: it never changes a file that already exists. After initialization, list created, skipped (identical) and kept (differs from the template, not modified) files. Replacing a kept file is the user's explicit decision (`--force`, which backs it up first).
