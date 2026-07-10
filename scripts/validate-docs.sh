#!/usr/bin/env bash
# Validates docs/*.md (Linux/macOS port of validate-docs.ps1): required files present,
# non-empty, no control chars, no unresolved TODO/TBD markers, README.md links every
# other doc.
#
# Usage:
#   ./validate-docs.sh [path-to-docs] [--json]
set -uo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
docs_root="$script_dir/../docs"
json=0
for arg in "$@"; do
  case "$arg" in
    --json) json=1 ;;
    *) docs_root="$arg" ;;
  esac
done

required_docs=(README.md architecture.md security.md workflows.md validation.md)

if [ ! -d "$docs_root" ]; then
  echo "docs root not found: $docs_root" >&2
  exit 1
fi

issue_files=()
issue_msgs=()

for doc in "${required_docs[@]}"; do
  path="$docs_root/$doc"
  if [ ! -f "$path" ]; then
    issue_files+=("$doc"); issue_msgs+=("required doc missing")
    continue
  fi
  if [ ! -s "$path" ]; then
    issue_files+=("$doc"); issue_msgs+=("doc is empty")
  fi
  if grep -Eq "TODO|TBD" "$path"; then
    issue_files+=("$doc"); issue_msgs+=("doc contains unresolved TODO/TBD marker")
  fi
  # Control-character check: bytes < 0x20 excluding tab/LF/CR.
  if LC_ALL=C grep -qP '[\x00-\x08\x0B\x0C\x0E-\x1F]' "$path" 2>/dev/null; then
    issue_files+=("$doc"); issue_msgs+=("doc contains control characters")
  fi
done

index_path="$docs_root/README.md"
if [ -f "$index_path" ]; then
  for doc in "${required_docs[@]}"; do
    [ "$doc" = "README.md" ] && continue
    if ! grep -qF "]($doc)" "$index_path"; then
      issue_files+=("README.md"); issue_msgs+=("index does not link $doc")
    fi
  done
fi

issue_count="${#issue_files[@]}"

if [ "$json" -eq 1 ]; then
  if [ "$issue_count" -eq 0 ]; then
    printf '{"docs":%d,"issues":0,"details":[]}\n' "${#required_docs[@]}"
  else
    printf '{"docs":%d,"issues":%d,"details":[' "${#required_docs[@]}" "$issue_count"
    for i in "${!issue_files[@]}"; do
      [ "$i" -gt 0 ] && printf ','
      if command -v jq >/dev/null 2>&1; then
        jq -nc --arg f "${issue_files[$i]}" --arg m "${issue_msgs[$i]}" '{file:$f,message:$m}'
      else
        printf '{"file":"%s","message":"%s"}' "${issue_files[$i]}" "${issue_msgs[$i]}"
      fi
    done
    printf ']}\n'
  fi
else
  if [ "$issue_count" -eq 0 ]; then
    echo "docs ok: files=${#required_docs[@]}"
  else
    echo "docs FAIL: issues=$issue_count"
    for i in "${!issue_files[@]}"; do
      echo "  ${issue_files[$i]}: ${issue_msgs[$i]}"
    done
  fi
fi

[ "$issue_count" -eq 0 ] || exit 1
exit 0
