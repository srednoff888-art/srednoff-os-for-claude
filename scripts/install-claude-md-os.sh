#!/usr/bin/env bash
set -euo pipefail

# Install the Claude MD OS template into ~/.claude/templates/claude-md-os
# and set up the global ~/.claude/CLAUDE.md bootstrap + code_review.md.

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source_root="$(cd "$script_dir/.." && pwd)"

claude_home="${HOME}/.claude"
dest_template="$claude_home/templates/claude-md-os"
stamp="$(date +%Y%m%d-%H%M%S)"

mkdir -p "$dest_template"

if [ "$source_root" != "$dest_template" ]; then
  echo "Copying template -> $dest_template"
  cp -rf "$source_root/." "$dest_template/"
else
  echo "Already running from the installed template location."
fi

cp -f "$dest_template/code_review.md" "$claude_home/code_review.md"
echo "Wrote $claude_home/code_review.md"

global_claude="$claude_home/CLAUDE.md"
marker="# Global Claude MD OS Bootstrap Rule"
read -r -d '' bootstrap <<'EOF' || true

# Global Claude MD OS Bootstrap Rule

At the start of work in any repository, check whether the project contains Claude MD OS files
(CLAUDE.md, code_review.md, .claude/rules/, .claude/skills/, .agent/).

If these files are missing and the repository is writable, initialize them from
~/.claude/templates/claude-md-os.

If a file already exists, do not overwrite silently: preserve existing content, append only
missing Claude MD OS sections, or create a timestamped backup before replacing.

After initialization, continue the user's task.

If automatic file creation is unsafe or blocked, report the exact command:

    ~/.claude/templates/claude-md-os/scripts/init-claude-project.sh .
EOF

if [ -f "$global_claude" ]; then
  if grep -qF "$marker" "$global_claude"; then
    echo "Bootstrap rule already present in global CLAUDE.md."
  else
    cp -f "$global_claude" "$global_claude.bak.$stamp"
    printf '%s\n' "$bootstrap" >> "$global_claude"
    echo "Appended Bootstrap rule to existing global CLAUDE.md (backup made)."
  fi
else
  printf '%s\n' "$bootstrap" > "$global_claude"
  echo "Created global CLAUDE.md with Bootstrap rule."
fi

chmod +x "$dest_template/scripts/"*.sh "$dest_template/.claude/hooks/"*.sh 2>/dev/null || true

echo ""
echo "Install complete. Add Claude MD OS to a project:"
echo "  ~/.claude/templates/claude-md-os/scripts/init-claude-project.sh /path/to/project"
