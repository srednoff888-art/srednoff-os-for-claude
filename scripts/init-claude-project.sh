#!/usr/bin/env bash
set -euo pipefail

# Initialize Claude MD OS files into a target project.
# - Only ever ships the OS's project-bootstrap surface (CLAUDE.md, code_review.md, AGENTS.md,
#   .claude/rules|skills|commands|hooks, .claude/settings*.example.json, .agent/**). The OS
#   repo's own about-itself files (README*, LICENSE, .gitignore, QUALITY.md, RELEASE.md,
#   docs/**, benchmarks/**, registry/**, skills-library/**) are NEVER copied into a target
#   project - a consumer project has no use for them, and registry/skills-library are meant
#   to be consumed via the ~/.claude/registry symlink, not duplicated per project.
# - CREATE-ONLY: it creates the files the project is missing and never changes one that
#   already exists. An existing file that differs from the template is left untouched and
#   listed in the report - whether or not it is committed, whether or not the project is a git
#   repo. A .bak file is not consent, and this script also runs in the background (global
#   SessionStart hook, doctor --fix-safe, apply-os-all --sync), where nobody is watching.
#   Pass --force to replace the files that differ (each is backed up to <file>.bak.<stamp>
#   first). Only a human at a prompt should.
# - Never deletes anything.
# - Never creates an active .claude/settings.json (only settings.example.json).
# --skip-existing-claude-md: kept for compatibility; create-only already leaves an existing
#   CLAUDE.md alone. Unlike plain create-only it also wins over --force for CLAUDE.md.
# --force: replace existing files that differ from the template (backup first). Opt-in only;
#   never passed by any automated path.

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
template_root="$(cd "$script_dir/.." && pwd)"

target="."
skip_existing_claude_md=0
force=0
for arg in "$@"; do
  case "$arg" in
    --skip-existing-claude-md) skip_existing_claude_md=1 ;;
    --force) force=1 ;;
    *) target="$arg" ;;
  esac
done
target="$(cd "$target" && pwd)"
stamp="$(date +%Y%m%d-%H%M%S)"

# Hard safety guard: never let target resolve to $HOME itself. This tool deploys a full
# project structure (rules/hooks/skills/CLAUDE.md/etc.) - $HOME is a user's global config
# root, never a "project", and mistakenly targeting it pollutes real global state. Defense
# in depth regardless of how target got here (bad argument, resolved symlink, future logic
# change) - not just a fix for the specific git-root bug below.
home_resolved="$(cd "$HOME" && pwd)"
if [ "$target" = "$home_resolved" ]; then
  echo "init-claude-project: refusing to init directly into \$HOME ($home_resolved) - this is not a project directory. Pass an explicit project path." >&2
  exit 1
fi

# NOTE: earlier versions of this script "preferred the git root" here (walked up via
# git rev-parse --show-toplevel to find an ancestor .git and re-targeted there). That
# walk has no bound: it can escape past the intended project into ANY unrelated ancestor
# repo, including a personal dotfiles repo at $HOME - which is exactly what happened
# during testing (a scratch path under $HOME/AppData/... silently resolved to $HOME
# because $HOME/.git existed, deploying the full OS - rules, hooks, skills, CLAUDE.md -
# directly into the user's home directory). init-claude-project.ps1 never had this
# logic and was never affected. Removed here for platform parity and safety: use the
# explicitly passed target as-is, exactly like the PowerShell port.

echo "Claude MD OS init"
echo "  Template: $template_root"
echo "  Target:   $target"
echo ""

created=0; updated=0; skipped=0; preserved=0; kept=0

# Walk template files, but only ship the project-bootstrap allow-list. Everything else in
# the template (README*, LICENSE, .gitignore, QUALITY.md, RELEASE.md, docs/, benchmarks/,
# registry/, skills-library/, scripts/, .git/, .github/, .claude-plugin/, top-level hooks/,
# .claude/settings.json) is the OS repo's own tooling/about-itself content and is never
# copied into a target project.
while IFS= read -r -d '' f; do
  rel="${f#$template_root/}"
  case "$rel" in
    CLAUDE.md|code_review.md|AGENTS.md) ;;
    .claude/rules/*|.claude/skills/*|.claude/commands/*|.claude/hooks/*) ;;
    .claude/settings.example.json|.claude/settings.windows.example.json) ;;
    .agent/*) ;;
    *) continue ;;
  esac

  if [ "$skip_existing_claude_md" -eq 1 ] && [ "$rel" = "CLAUDE.md" ] && [ -f "$target/CLAUDE.md" ]; then
    echo "  ! $rel  (preserved - project's own CLAUDE.md kept active)"
    preserved=$((preserved + 1))
    continue
  fi

  dest="$target/$rel"
  mkdir -p "$(dirname "$dest")"

  if [ -e "$dest" ]; then
    if cmp -s "$dest" "$f"; then
      echo "  = $rel"
      skipped=$((skipped+1))
    else
      if [ "$force" -eq 1 ]; then
        cp -f "$dest" "$dest.bak.$stamp"
        cp -f "$f" "$dest"
        echo "  ~ $rel  (backup: $(basename "$dest.bak.$stamp"))"
        updated=$((updated+1))
      else
        echo "  ! $rel  (kept - differs from the template; not modified, pass --force to replace)"
        kept=$((kept+1))
      fi
    fi
  else
    cp -f "$f" "$dest"
    echo "  + $rel"
    created=$((created+1))
  fi
done < <(find "$template_root" -type f -print0)

echo ""
echo "Created: $created  Updated: $updated  Skipped: $skipped  Preserved: $preserved  Kept (differs, not modified): $kept"
echo ""
echo "Hooks are NOT active. To enable them:"
echo "  cp .claude/settings.example.json .claude/settings.json"
echo "  chmod +x .claude/hooks/*.sh"

# Generate PROFILE.lock (cached skill selection for the stack), if the registry is available.
gen_lock="$script_dir/gen-profile-lock.sh"
core_reg="$HOME/.claude/registry/CORE-300.md"
if [ -f "$gen_lock" ] && [ -f "$core_reg" ]; then
  echo ""
  bash "$gen_lock" "$target"
fi
