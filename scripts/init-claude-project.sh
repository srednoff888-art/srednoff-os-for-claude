#!/usr/bin/env bash
set -euo pipefail

# Initialize Claude MD OS files into a target project.
# - Never overwrites silently: existing files backed up as <file>.bak.<timestamp>.
# - Never deletes anything.
# - Never creates an active .claude/settings.json (only settings.example.json).

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
template_root="$(cd "$script_dir/.." && pwd)"

target="${1:-.}"
target="$(cd "$target" && pwd)"
stamp="$(date +%Y%m%d-%H%M%S)"

# If inside a git repo, prefer the git root.
if git -C "$target" rev-parse --show-toplevel >/dev/null 2>&1; then
  target="$(git -C "$target" rev-parse --show-toplevel)"
fi

echo "Claude MD OS init"
echo "  Template: $template_root"
echo "  Target:   $target"
echo ""

created=0; updated=0; skipped=0

# Walk all template files except scripts/ and any settings.json
while IFS= read -r -d '' f; do
  rel="${f#$template_root/}"
  case "$rel" in
    scripts/*) continue ;;
    .claude/settings.json) continue ;;
  esac

  dest="$target/$rel"
  mkdir -p "$(dirname "$dest")"

  if [ -e "$dest" ]; then
    if cmp -s "$dest" "$f"; then
      echo "  = $rel"
      skipped=$((skipped+1))
    else
      cp -f "$dest" "$dest.bak.$stamp"
      cp -f "$f" "$dest"
      echo "  ~ $rel  (backup: $(basename "$dest.bak.$stamp"))"
      updated=$((updated+1))
    fi
  else
    cp -f "$f" "$dest"
    echo "  + $rel"
    created=$((created+1))
  fi
done < <(find "$template_root" -type f -print0)

echo ""
echo "Created: $created  Updated: $updated  Skipped: $skipped"
echo ""
echo "Hooks are NOT active. To enable them:"
echo "  cp .claude/settings.example.json .claude/settings.json"
echo "  chmod +x .claude/hooks/*.sh"
