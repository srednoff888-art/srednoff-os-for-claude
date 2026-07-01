# Stop hook - quality reminder to stderr. PowerShell, no jq.
# Wire: powershell -NoProfile -ExecutionPolicy Bypass -File .claude/hooks/quality-reminder.ps1
[Console]::Error.WriteLine("Claude MD OS reminder:")
[Console]::Error.WriteLine("- Ran relevant tests/build/lint?")
[Console]::Error.WriteLine("- Checked security and data-loss risks?")
[Console]::Error.WriteLine("- Reported assumptions and validation commands?")
exit 0
