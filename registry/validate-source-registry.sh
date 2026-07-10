#!/usr/bin/env bash
# Validates design-source-registry.json (Linux/macOS port of validate-source-registry.ps1
# - no such port exists upstream in srednoff-os, the Codex sibling; written here for
# bash 3.2 parity). Required fields present/non-empty per source, no duplicate ids,
# risk in {low,medium,high}, high-risk sources must require a user prompt.
#
# Usage:
#   ./validate-source-registry.sh [path-to-design-source-registry.json] [--json]
#
# Requires jq.
set -uo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
registry_path="$script_dir/design-source-registry.json"
json=0
for arg in "$@"; do
  case "$arg" in
    --json) json=1 ;;
    *) registry_path="$arg" ;;
  esac
done

if ! command -v jq >/dev/null 2>&1; then
  echo "validate-source-registry: jq not found in PATH" >&2
  exit 1
fi
if [ ! -f "$registry_path" ]; then
  echo "validate-source-registry: source registry not found: $registry_path" >&2
  exit 1
fi

result="$(jq '
  def required_fields: ["id","name","url","kind","domains","risk","license","provenance","vetted","copy_policy","use_when","requires_user_prompt"];

  (.sources // []) as $sources |
  # duplicate id detection: any id appearing more than once gets one issue per extra occurrence
  ( $sources | map((.id // "") | if . == "" then "<missing-id>" else . end)
    | group_by(.) | map(select(length > 1)) | map(.[1:][] | {id: ., field: "id", message: "duplicate source id"})
  ) as $dupe_issues |
  ( [ $sources[] | . as $s |
      (($s.id // "") | if . == "" then "<missing-id>" else . end) as $id |
      ( required_fields[] as $f |
        if ($s | has($f) | not) then {id: $id, field: $f, message: "missing required field"}
        elif ($s[$f] == null) then {id: $id, field: $f, message: "field is null"}
        elif (($s[$f] | type) == "string" and ($s[$f] | gsub("^\\s+|\\s+$"; "") == "")) then {id: $id, field: $f, message: "field is empty"}
        elif (($f == "domains" or $f == "use_when") and (($s[$f] | type) == "array") and (($s[$f] | length) == 0)) then {id: $id, field: $f, message: "array is empty"}
        else empty end
      ),
      ( if ($s.risk != null) and (["low","medium","high"] | index($s.risk) | not) then {id: $id, field: "risk", message: "risk must be low, medium, or high"} else empty end ),
      ( if ($s.risk == "high") and ($s.requires_user_prompt != true) then {id: $id, field: "requires_user_prompt", message: "high-risk sources must require user prompt"} else empty end ),
      ( if ($s | has("vetted")) and (($s.vetted | type) != "boolean") then {id: $id, field: "vetted", message: "vetted must be boolean"} else empty end )
    ]
  ) as $field_issues |
  ( (if (.name // "") == "" then [{id:"registry", field:"name", message:"missing registry name"}] else [] end) +
    (if ($sources | length) == 0 then [{id:"registry", field:"sources", message:"registry has no sources"}] else [] end) +
    $dupe_issues + $field_issues
  ) as $issues |
  {
    name: "SREDNOFF OS source registry validator",
    registry: $ARGS.positional[0],
    sources: ($sources | length),
    issues: ($issues | length),
    details: $issues
  }
' --args "$registry_path" < "$registry_path")"

issue_count="$(printf '%s' "$result" | jq -r '.issues')"

if [ "$json" -eq 1 ]; then
  printf '%s\n' "$result"
else
  source_count="$(printf '%s' "$result" | jq -r '.sources')"
  if [ "$issue_count" -eq 0 ]; then
    echo "source registry ok: sources=$source_count"
  else
    echo "source registry FAIL: issues=$issue_count"
    printf '%s' "$result" | jq -r '.details[] | "\(.id)\t\(.field)\t\(.message)"'
  fi
fi

[ "$issue_count" -eq 0 ] || exit 1
