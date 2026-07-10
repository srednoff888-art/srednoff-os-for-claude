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

  # Read the whole file into an array (bash-3.2-safe: while-read, not mapfile) so a
  # YAML block-scalar description ("description: >" / "|") can look ahead at its
  # indented continuation lines - matching them requires index access, not a single
  # streamed pass.
  file_lines=()
  while IFS= read -r file_line || [ -n "$file_line" ]; do
    file_lines+=("$file_line")
  done < "$skill_file"

  in_frontmatter=0
  seen_first=0
  total_lines="${#file_lines[@]}"
  idx=0
  while [ "$idx" -lt "$total_lines" ]; do
    line="${file_lines[$idx]}"
    if [ "$line" = "---" ]; then
      if [ "$seen_first" -eq 0 ]; then in_frontmatter=1; seen_first=1; idx=$((idx + 1)); continue
      else break
      fi
    fi
    if [ "$in_frontmatter" -eq 1 ]; then
      if printf '%s' "$line" | grep -Eq '^[[:space:]]*name:[[:space:]]*[a-z0-9][a-z0-9-]{1,62}[[:space:]]*$'; then
        name_ok=1
      fi
      if printf '%s' "$line" | grep -Eq '^[[:space:]]*description:[[:space:]]*.+$'; then
        raw_value="$(printf '%s' "$line" | sed -E 's/^[[:space:]]*description:[[:space:]]*//')"
        trimmed_value="$(printf '%s' "$raw_value" | sed -E 's/^[[:space:]]+|[[:space:]]+$//g')"
        case "$trimmed_value" in
          '>'|'|'|'>-'|'|-'|'>+'|'|+')
            # Block scalar - the description is the indented lines that follow.
            block_value=""
            child=$((idx + 1))
            while [ "$child" -lt "$total_lines" ]; do
              child_line="${file_lines[$child]}"
              case "$child_line" in
                '---') break ;;
                [[:space:]]*[!\ ]*) block_value="$block_value $(printf '%s' "$child_line" | sed -E 's/^[[:space:]]+|[[:space:]]+$//g')" ;;
                *) break ;;
              esac
              child=$((child + 1))
            done
            block_value="$(printf '%s' "$block_value" | sed -E 's/^[[:space:]]+//')"
            block_len="${#block_value}"
            if [ "$block_len" -ge 20 ] && [ "$block_len" -le 1024 ]; then desc_ok=1; else desc_ok=0; fi
            ;;
          *)
            value="$(printf '%s' "$trimmed_value" | sed -E 's/^"(.*)"$/\1/; s/^'"'"'(.*)'"'"'$/\1/')"
            value_len="${#value}"
            if [ "$value_len" -ge 20 ] && [ "$value_len" -le 1024 ]; then desc_ok=1; else desc_ok=0; fi
            ;;
        esac
      fi
    fi
    idx=$((idx + 1))
  done

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
