#!/usr/bin/env bash
# SREDNOFF OS source ranker (Linux/macOS port of source-ranker.ps1 - no such port
# exists upstream in srednoff-os, the Codex sibling; written from scratch here to
# keep bash 3.2 parity, same house rule as every other script pair in this repo).
# Scores external UI/3D/design/growth sources for a task brief against
# design-source-registry.json (license/provenance/vetted/copy_policy metadata), so
# the agent gets a ranked shortlist with explicit gates instead of picking a
# component source from memory.
#
# Usage:
#   ./source-ranker.sh --brief "3d product configurator" --max 8
#   ./source-ranker.sh --brief "shadcn landing page" --json
#
# Requires jq (same dependency as the hooks and mode-router.sh).
set -uo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
registry="$script_dir/design-source-registry.json"
inventory="$script_dir/mcp-inventory.json"
mode_router="$script_dir/mode-router.sh"

if ! command -v jq >/dev/null 2>&1; then
  echo "source-ranker: jq not found in PATH" >&2
  exit 1
fi
if [ ! -f "$registry" ]; then
  echo "source-ranker: design source registry not found: $registry" >&2
  exit 1
fi

project="."
brief=""
max=8
json=0
while [ $# -gt 0 ]; do
  case "$1" in
    --project) project="$2"; shift 2 ;;
    --brief) brief="$2"; shift 2 ;;
    --max) max="$2"; shift 2 ;;
    --json) json=1; shift ;;
    *) shift ;;
  esac
done

lower="$(printf '%s' "$brief" | tr '[:upper:]' '[:lower:]')"

# Domain classification mirrors source-ranker.ps1's Test-Any blocks: keep the two
# implementations behaviorally identical, not just structurally similar.
domains=()
if printf '%s' "$lower" | grep -Eq 'ui/ux|ux|ui\b|web design|landing|dashboard|component|shadcn|figma|canva|21st|magic ui|aceternity|origin ui|react bits|design|interface|ui kit'; then
  domains+=("ui-ux" "web-design")
fi
if printf '%s' "$lower" | grep -Eq '\b3d\b|three|react three fiber|r3f|webgl|webgpu|gltf|glb|model-viewer|babylon|shader|xr|ar\b|configurator|asset|model|texture|hdri'; then
  domains+=("3d-web")
fi
if printf '%s' "$lower" | grep -Eq 'seo|ppc|growth|ads|google ads|meta ads|serp|conversion|analytics'; then
  domains+=("seo-ppc-growth" "growth")
fi
if [ "${#domains[@]}" -eq 0 ]; then
  domains=("ui-ux" "web-design")
fi
domain_json="$(printf '%s\n' "${domains[@]}" | jq -R . | jq -s 'unique')"

mode="standard"
turbo="false"
if [ -f "$mode_router" ]; then
  mode_out="$(bash "$mode_router" --brief "$brief" --json 2>/dev/null || true)"
  if [ -n "$mode_out" ]; then
    mode="$(printf '%s' "$mode_out" | jq -r '.mode // "standard"')"
    turbo="$(printf '%s' "$mode_out" | jq -r '.turbo // false')"
  fi
fi

inventory_json="null"
[ -f "$inventory" ] && inventory_json="$(cat "$inventory")"

# Scoring pass runs in jq: same weights/penalties as the PowerShell port, ported
# term-for-term so `--json` output is comparable across platforms.
jq -n \
  --slurpfile registry_arr "$registry" \
  --argjson domains "$domain_json" \
  --arg lower "$lower" \
  --arg mode "$mode" \
  --argjson turbo "$turbo" \
  --argjson inventory "$inventory_json" \
  --argjson max "$max" \
  --arg project "$project" '
  def matchkey: ascii_downcase | gsub("[^a-z0-9]"; "");
  def risk_penalty: if . == "low" then 2.0 elif . == "medium" then 0.0 elif . == "high" then -4.0 else -1.0 end;

  ($registry_arr[0].sources) as $sources |
  ($lower | matchkey) as $brief_key |
  ["shadcn","21st","magic","aceternity","origin","react bits","figma","canva","three","r3f","gltf","glb","model-viewer","babylon","sketchfab","poly haven","ambientcg"] as $named_tokens |

  ($sources | map(
    . as $s |
    ($s.domains // []) as $sdomains |
    ([$sdomains[] | select(. as $d | $domains | index($d))]) as $domain_matches |
    (($s.id // "") + " " + ($s.name // "") + " " + ($s.kind // "") | matchkey) as $name_key |

    ( [0.0] +
      (if ($domain_matches | length) > 0 then [10.0 * ($domain_matches | length)] else [] end) +
      ([($s.use_when // [])[] | ascii_downcase as $t | select($lower | contains($t))] | map(3.0)) +
      ($named_tokens | map(. as $tok | ($tok | matchkey) as $tokkey | select(
          (($lower | contains($tok)) or ($brief_key | contains($tokkey))) and ($name_key | contains($tokkey))
        ) | 6.0)) +
      (if (($lower | test("ui kit|component|components|landing|dashboard")) and (($s.kind // "") | test("component|registry|marketplace|design"))) then [4.0] else [] end) +
      (if (($lower | test("3d asset|3d assets|gltf|glb|\\bmodel\\b|\\btexture\\b|\\bhdri\\b|\\bar\\b")) and (($sdomains | index("3d-web")) or (($s.kind // "") | test("3d|asset|model|texture|optimizer")))) then [5.0] else [] end) +
      (if ($mode == "turbo") or $turbo then [2.0] else [] end) +
      [($s.risk // "") | risk_penalty] +
      (if ($s.vetted // false) then [1.5] else [-0.5] end) +
      (if (($s.license // "") == "") then [-3.0]
       elif (($s.license // "") | test("varies|verify|user-provided")) then [-0.5]
       else [0.75] end) +
      (if (($s.provenance // "") == "") then [-2.0] else [] end) +
      (if (($s.copy_policy // "") == "") then [-1.0] else [] end) +
      (if ($s.requires_user_prompt // false) then [-0.5] else [] end) +
      (if ($s.connector // "") != "" then
        (if ($inventory != null and ([$inventory.items[]? | select(.name == $s.connector and .enabled)] | length) > 0)
         then [2.0] else [-1.0] end)
       else [] end)
    ) as $deltas |
    ($deltas | add) as $score |

    ( [] +
      (if ($s.vetted // false) then [] else ["unvetted-source-review"] end) +
      (if (($s.license // "") == "") then ["missing-license-metadata"]
       elif (($s.license // "") | test("varies|verify|user-provided")) then ["license-provenance-review"] else [] end) +
      (if (($s.provenance // "") == "") then ["missing-provenance-metadata"] else [] end) +
      (if (($s.copy_policy // "") == "") then ["missing-copy-policy"] else [] end) +
      (if ($s.requires_user_prompt // false) then ["ask-user-before-connector-or-external-copy"] else [] end) +
      (if ($s.connector // "") != "" then
        (if ($inventory != null and ([$inventory.items[]? | select(.name == $s.connector and .enabled)] | length) > 0)
         then [] else ["connector-availability-check"] end)
       else [] end) +
      (if (($s.risk // "") != "low") then ["license-provenance-review"] else [] end) +
      (if (($sdomains | index("3d-web")) or (($s.kind // "") | test("3d|asset|model|texture|optimizer"))) then ["asset-size-performance-budget"] else [] end) +
      (if (($s.kind // "") | test("component|registry|marketplace|design")) then ["accessibility-responsive-visual-qa"] else [] end)
    ) as $gates |

    {
      id: $s.id, name: $s.name, url: $s.url, kind: $s.kind, risk: $s.risk,
      score: ($score * 100 | round / 100),
      reasons: [],
      gates: ($gates | unique),
      license: ($s.license // ""), provenance: ($s.provenance // ""),
      vetted: ($s.vetted // false), copy_policy: ($s.copy_policy // ""),
      connector: $s.connector, requires_user_prompt: ($s.requires_user_prompt // false)
    }
  ) | sort_by(-.score) | .[0:$max]) as $ranked |

  { name: "SREDNOFF OS source ranker", project: $project, mode: $mode, domains: $domains, ranked_sources: $ranked }
' > /tmp/source-ranker-result.$$.json

result="$(cat /tmp/source-ranker-result.$$.json)"
rm -f /tmp/source-ranker-result.$$.json

if [ "$json" -eq 1 ]; then
  printf '%s\n' "$result"
else
  mode_out2="$(printf '%s' "$result" | jq -r '.mode')"
  domains_out="$(printf '%s' "$result" | jq -r '.domains | join(", ")')"
  count_out="$(printf '%s' "$result" | jq -r '.ranked_sources | length')"
  echo "SREDNOFF OS source ranking: mode=$mode_out2 | domains=$domains_out | sources=$count_out"
  printf '%s' "$result" | jq -r '.ranked_sources[] | "- \(.name) | score=\(.score) | risk=\(.risk) | gates=\(.gates | join(","))"'
fi
