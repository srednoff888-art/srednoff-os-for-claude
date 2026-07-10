#!/usr/bin/env bash
# Fast metadata smoke check for templates/claude-md-os/skills-library/*/SKILL.md (Linux/
# macOS port of validate-skills-library.ps1). Name pattern, description length/presence,
# frontmatter well-formedness.
#
# Usage:
#   ./validate-skills-library.sh [path-to-skills-library] [--json]
set -uo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
skills_root="$script_dir/../skills-library"
json=0
for arg in "$@"; do
  case "$arg" in
    --json) json=1 ;;
    *) skills_root="$arg" ;;
  esac
done

if [ ! -d "$skills_root" ]; then
  echo "skills-library not found: $skills_root (nothing to validate)"
  [ "$json" -eq 1 ] && echo '{"ok":0,"failed":0}'
  exit 0
fi

ok=0
fail_names=()
fail_msgs=()

for skill_dir in "$skills_root"/*/; do
  [ -d "$skill_dir" ] || continue
  skill_file="$skill_dir/SKILL.md"
  [ -f "$skill_file" ] || continue
  skill_name="$(basename "$skill_dir")"

  name_ok=0
  desc_ok=0
  frontmatter_ok=0
  first_line="$(head -n1 "$skill_file")"
  [ "$first_line" = "---" ] && frontmatter_ok=1

  # Only scan the frontmatter block (between the first two "---" lines).
  in_frontmatter=0
  seen_first=0
  while IFS= read -r line; do
    if [ "$line" = "---" ]; then
      if [ "$seen_first" -eq 0 ]; then in_frontmatter=1; seen_first=1; continue
      else break
      fi
    fi
    [ "$in_frontmatter" -eq 1 ] || continue
    if printf '%s' "$line" | grep -Eq '^[[:space:]]*name:[[:space:]]*[a-z0-9][a-z0-9-]{1,62}[[:space:]]*$'; then
      name_ok=1
    fi
    if printf '%s' "$line" | grep -Eq '^[[:space:]]*description:[[:space:]]*.+$'; then
      value="$(printf '%s' "$line" | sed -E 's/^[[:space:]]*description:[[:space:]]*//; s/^"(.*)"$/\1/; s/^'"'"'(.*)'"'"'$/\1/')"
      value_len="${#value}"
      if [ "$value_len" -ge 20 ] && [ "$value_len" -le 1024 ]; then desc_ok=1; else desc_ok=0; fi
    fi
  done < "$skill_file"

  errors=""
  [ "$frontmatter_ok" -eq 1 ] || errors="${errors}missing frontmatter start; "
  lower_name="$(printf '%s' "$skill_name" | tr '[:upper:]' '[:lower:]')"
  [ "$skill_name" = "$lower_name" ] || errors="${errors}directory name must be lowercase; "
  [ "$name_ok" -eq 1 ] || errors="${errors}missing or invalid name (lowercase, alnum+hyphen, 2-63 chars); "
  [ "$desc_ok" -eq 1 ] || errors="${errors}missing, too-short (<20 chars), or too-long (>1024 chars) description; "

  if [ -z "$errors" ]; then
    ok=$((ok + 1))
  else
    fail_names+=("$skill_name")
    fail_msgs+=("$errors")
  fi
done

failed="${#fail_names[@]}"

if [ "$json" -eq 1 ]; then
  if [ "$failed" -eq 0 ]; then
    printf '{"ok":%d,"failed":0,"failures":[]}\n' "$ok"
  else
    printf '{"ok":%d,"failed":%d,"failures":[' "$ok" "$failed"
    for i in "${!fail_names[@]}"; do
      [ "$i" -gt 0 ] && printf ','
      if command -v jq >/dev/null 2>&1; then
        jq -nc --arg s "${fail_names[$i]}" --arg e "${fail_msgs[$i]}" '{skill:$s,errors:$e}'
      else
        printf '{"skill":"%s","errors":"%s"}' "${fail_names[$i]}" "${fail_msgs[$i]}"
      fi
    done
    printf ']}\n'
  fi
else
  echo "skills-library validation: ok=$ok failed=$failed"
  for i in "${!fail_names[@]}"; do
    echo "  FAIL ${fail_names[$i]}: ${fail_msgs[$i]}"
  done
fi

[ "$failed" -eq 0 ] || exit 1
exit 0
