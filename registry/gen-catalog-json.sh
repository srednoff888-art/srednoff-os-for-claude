#!/usr/bin/env bash
# Generate CORE-300.json - a machine-readable export of the CORE-300.md catalog - so
# external tools (installers, selectors, dashboards) can consume the registry without
# re-implementing the markdown line format. CORE-300.md stays the single source of
# truth; this file is a derived artifact (same relationship as PROFILE.lock).
#
# Record line format parsed (validated by validate-catalog-format.sh):
#   <id>. `<name>` [tag][tag]... <SOURCE[:detail]> [— <description>]
# Group (G1/G2/G3) is derived from the nearest preceding "## G..." header; the catalog
# grew via appendices, so headers repeat and ids are NOT monotonic in document order.
#
# Usage:
#   ./gen-catalog-json.sh            # writes CORE-300.json next to CORE-300.md
#   ./gen-catalog-json.sh --check    # regenerate to a temp file and diff (CI gate)
#
# Requires jq (same dependency as the hooks). Output is deterministic: no timestamps,
# so `--check` can gate CI on catalog/JSON drift.
set -uo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
core="$script_dir/CORE-300.md"
out="$script_dir/CORE-300.json"
mode="${1:-generate}"

if ! command -v jq >/dev/null 2>&1; then
  echo "gen-catalog-json: jq not found in PATH" >&2
  exit 1
fi
if [ ! -f "$core" ]; then
  echo "gen-catalog-json: CORE-300.md not found: $core" >&2
  exit 1
fi

# awk pass: one TSV row per record (id, name, tags-csv, source-raw, description, group).
# Tabs inside fields are normalized to spaces (none expected in practice).
tsv() {
  awk '
    /^## / {
      if ($0 ~ /^## *G(ROUP)? *1/)      grp = "G1"
      else if ($0 ~ /^## *G(ROUP)? *2/) grp = "G2"
      else if ($0 ~ /^## *G(ROUP)? *3/) grp = "G3"
      else                              grp = ""
      next
    }
    /^[[:space:]]*[0-9]+\.[[:space:]]*`/ {
      line = $0
      match(line, /^[[:space:]]*[0-9]+/)
      id = substr(line, RSTART, RLENGTH)
      gsub(/[[:space:]]/, "", id)

      rest = line
      sub(/^[^`]*`/, "", rest)
      name = rest
      sub(/`.*$/, "", name)
      sub(/^[^`]*`/, "", rest)

      desc = ""
      if (match(rest, / — /)) {
        desc = substr(rest, RSTART + RLENGTH)
        rest = substr(rest, 1, RSTART - 1)
      }

      tags = ""
      while (match(rest, /\[[^]]+\]/)) {
        t = substr(rest, RSTART + 1, RLENGTH - 2)
        tags = (tags == "" ? t : tags "," t)
        rest = substr(rest, RSTART + RLENGTH)
      }

      src = rest
      gsub(/^[[:space:]]+/, "", src)
      gsub(/[[:space:]]+$/, "", src)
      gsub(/\t/, " ", name); gsub(/\t/, " ", desc); gsub(/\t/, " ", src)

      print id "\t" name "\t" tags "\t" src "\t" desc "\t" grp
    }
  ' "$core"
}

json="$(tsv | jq -Rn '
  {
    schema_version: 1,
    source: "CORE-300.md",
    entries: [
      inputs | split("\t") | {
        id: (.[0] | tonumber),
        name: .[1],
        tags: (if .[2] == "" then [] else (.[2] | split(",")) end),
        source: (if .[3] == "" then null else (.[3] | split(" ")[0] | split(":")[0]) end),
        source_raw: (if .[3] == "" then null else .[3] end),
        group: (if .[5] == "" then null else .[5] end),
        description: (if .[4] == "" then null else .[4] end)
      }
    ]
  } | .count = (.entries | length)
')"

expected="$(grep -Ec '^[[:space:]]*[0-9]+\.[[:space:]]*`' "$core" || true)"
actual="$(printf '%s' "$json" | jq '.count')"
if [ "$expected" != "$actual" ]; then
  echo "gen-catalog-json: record count mismatch: markdown=$expected json=$actual" >&2
  exit 1
fi

case "$mode" in
  --check)
    if [ ! -f "$out" ]; then
      echo "gen-catalog-json: --check: $out does not exist (run without --check first)" >&2
      exit 1
    fi
    if printf '%s\n' "$json" | diff -q - "$out" >/dev/null 2>&1; then
      echo "gen-catalog-json: OK - CORE-300.json is in sync ($actual records)"
    else
      echo "gen-catalog-json: DRIFT - CORE-300.json is stale; regenerate with ./gen-catalog-json.sh" >&2
      exit 1
    fi
    ;;
  *)
    printf '%s\n' "$json" > "$out"
    echo "gen-catalog-json: wrote $out ($actual records)"
    ;;
esac
