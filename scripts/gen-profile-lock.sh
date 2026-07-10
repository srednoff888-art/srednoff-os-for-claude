#!/usr/bin/env bash
# Generate .claude/PROFILE.lock.md - a cached skill-selection for the project (Linux/macOS
# port of gen-profile-lock.ps1), so the agent does not have to grep CORE-300.md every
# session. Heuristically classifies the project (manifests/name), picks dominant domain
# tags, and pulls candidate entries from the global CORE-300.md by those tags. This is a
# STARTING set - the agent refines per task (Principle #1: quality first).
#
# Usage:
#   ./gen-profile-lock.sh .
#   ./gen-profile-lock.sh /path/to/project
set -uo pipefail

target="${1:-.}"
target="$(cd "$target" && pwd)"
name="$(basename "$target")"
core="$HOME/.claude/registry/CORE-300.md"
if [ ! -f "$core" ]; then echo "CORE-300.md not found: $core" >&2; exit 1; fi
total="$(grep -Ec '^[[:space:]]*[0-9]+\.' "$core" || true)"

# Stamp the OS version this project was last synced against, so doctor can detect
# template drift without needing a separate marker file.
version_file="$HOME/.claude/registry/version.json"
os_version="unknown"
if [ -f "$version_file" ] && command -v jq >/dev/null 2>&1; then
  os_version="$(jq -r '.version // "unknown"' "$version_file" 2>/dev/null || echo "unknown")"
fi

tags=()
add_tag() {
  local t="$1" existing
  # ${tags[@]+...} guard: on the first call tags is empty, and a bare "${tags[@]}" under
  # `set -u` on bash < 4.4 (macOS /bin/bash 3.2) raises "unbound variable".
  for existing in ${tags[@]+"${tags[@]}"}; do [ "$existing" = "$t" ] && return 0; done
  tags+=("$t")
}

# --- heuristic classification ---
if [ -f "$target/package.json" ]; then
  add_tag "web"; add_tag "frontend"
  pkg="$(cat "$target/package.json" 2>/dev/null || true)"
  printf '%s' "$pkg" | grep -Eq '"three"|@react-three' && { add_tag "3d"; add_tag "animation"; }
  printf '%s' "$pkg" | grep -Eq 'framer-motion|gsap' && add_tag "animation"
  printf '%s' "$pkg" | grep -Eq '@anthropic|openai|ai-sdk' && add_tag "ai"
  printf '%s' "$pkg" | grep -Eq 'tailwind|shadcn' && add_tag "design"
fi
if [ -f "$target/requirements.txt" ] || [ -f "$target/pyproject.toml" ]; then
  add_tag "backend"
  py="$(cat "$target/requirements.txt" 2>/dev/null || true; cat "$target/pyproject.toml" 2>/dev/null || true)"
  printf '%s' "$py" | grep -Eq 'ccxt|backtest|binance|trading' && add_tag "trading"
  printf '%s' "$py" | grep -Eq 'torch|sklearn|scikit|tensorflow|pandas|numpy' && { add_tag "ml"; add_tag "data"; }
fi
find "$target" -maxdepth 1 -name "*.ps1" -print -quit 2>/dev/null | grep -q . && add_tag "windows"
if [ -f "$target/Dockerfile" ] || find "$target" -name "*.tf" -print -quit 2>/dev/null | grep -q .; then
  add_tag "infra"; add_tag "devops"
fi
echo "$name" | grep -Eqi 'amazon|fba' && { add_tag "amazon"; add_tag "business"; add_tag "marketing"; }
echo "$name" | grep -Eqi 'seo' && add_tag "seo"
echo "$name" | grep -Eqi 'freelance|outreach|strategy|sales|crm' && { add_tag "sales"; add_tag "marketing"; }
echo "$name" | grep -Eqi 'design' && add_tag "design"
[ "${#tags[@]}" -eq 0 ] && add_tag "web"

# --- pull candidates from CORE-300 by tags (dedupe by skill name so G2/G3 variants of the
# same capability collapse) ---
pattern="$(printf '\\[%s\\]|' "${tags[@]}")"
pattern="${pattern%|}"
candidates="$(grep -E "$pattern" "$core" | grep -E '^[[:space:]]*[0-9]+\.' | sed 's/^[[:space:]]*//; s/[[:space:]]*$//' | awk '
  {
    key = $0
    if (match($0, /`[^`]+`/)) key = substr($0, RSTART, RLENGTH)
    if (!(key in seen)) { seen[key] = 1; print }
  }
' | head -n 40)"
cand_count="$(printf '%s\n' "$candidates" | grep -c . || true)"
[ -z "$candidates" ] && cand_count=0

# --- write lock ---
lock_dir="$target/.claude"
mkdir -p "$lock_dir"
lock="$lock_dir/PROFILE.lock.md"
ts="$(date +"%Y-%m-%d %H:%M")"
tags_csv="$(printf '%s, ' "${tags[@]}")"; tags_csv="${tags_csv%, }"

{
  echo "# PROFILE.lock - cached skill selection for project '$name'"
  echo ""
  echo "Generated $ts by gen-profile-lock.sh. CACHE: load this instead of grepping CORE-300.md ($total entries) each session = context saving."
  echo "OS version: $os_version (see ~/.claude/registry/version.json for the current template version)."
  echo "Principle #1: QUALITY FIRST, economy only at equal quality. Starting set - refine per task; any CORE-300 entry may be called."
  echo "Model routing: see 80-model-routing.md (G1~Haiku, G2~Sonnet, G3~Opus by required quality)."
  echo "External agents (GH/WSH/VOLT/FTB/EXT) = unvetted until github-research + license check (see 70-skills-registry.md)."
  echo ""
  echo "## Dominant tags"
  echo "\`$tags_csv\`"
  echo ""
  echo "## Candidates by tag (from CORE-300, up to 40). G1 generous | G2 targeted 3-7 | G3 on demand"
  echo ""
  if [ "$cand_count" -eq 0 ]; then
    echo "_(no matches - classify manually via SELECTION-PROTOCOL.md)_"
  else
    printf '%s\n' "$candidates" | sed 's/^/- /'
  fi
  echo ""
  echo "Full catalog: ~/.claude/registry/CORE-300.md | protocol: SELECTION-PROTOCOL.md"
} > "$lock"

# --- Embed a compact selection into CLAUDE.md (always-loaded) so the agent sees the picks
# without needing a separate read of PROFILE.lock. Idempotent via markers. ---
claude_md="$target/CLAUDE.md"
if [ -f "$claude_md" ]; then
  names=()
  # Prefer immediately-usable INST/ANTH skills first, then fill with the rest.
  for pref_inst in 1 0; do
    [ "${#names[@]}" -ge 8 ] && break
    while IFS= read -r line; do
      [ -z "$line" ] && continue
      is_inst=0
      printf '%s' "$line" | grep -Eq ' INST| ANTH' && is_inst=1
      [ "$pref_inst" -eq 1 ] && [ "$is_inst" -eq 0 ] && continue
      [ "$pref_inst" -eq 0 ] && [ "$is_inst" -eq 1 ] && continue
      nm=""
      if [[ "$line" =~ \`([^\`]+)\` ]]; then nm="${BASH_REMATCH[1]}"; fi
      [ -z "$nm" ] && continue
      already=0
      for existing in "${names[@]:-}"; do [ "$existing" = "$nm" ] && already=1; done
      [ "$already" -eq 0 ] && names+=("$nm")
      [ "${#names[@]}" -ge 8 ] && break
    done <<< "$candidates"
  done
  sel="$(printf '%s, ' "${names[@]:-}")"; sel="${sel%, }"

  m0="<!-- SREDNOFF-OS:SELECTION -->"
  m1="<!-- /SREDNOFF-OS:SELECTION -->"
  block="$m0"$'\n'"> **SREDNOFF OS - skills for this project** (full list: .claude/PROFILE.lock.md - read it first) | tags: $tags_csv | top: $sel"$'\n'"$m1"

  md_content="$(cat "$claude_md")"
  if printf '%s' "$md_content" | grep -qF "$m0"; then
    # Replace existing block between markers (idempotent re-run).
    awk -v block="$block" '
      BEGIN { in_block = 0 }
      /<!-- SREDNOFF-OS:SELECTION -->/ { print block; in_block = 1; next }
      /<!-- \/SREDNOFF-OS:SELECTION -->/ { in_block = 0; next }
      !in_block { print }
    ' "$claude_md" > "$claude_md.tmp" && mv "$claude_md.tmp" "$claude_md"
  else
    # Insert after the first line (title), matching the ps1 version's placement.
    { head -n 1 "$claude_md"; echo ""; echo "$block"; echo ""; tail -n +2 "$claude_md"; } > "$claude_md.tmp" && mv "$claude_md.tmp" "$claude_md"
  fi
fi

# --- Install actual skill content for skills-library-backed candidates (v1.17). CORE-300
# has 2000+ text-only catalog lines; only a curated subset (srednoff-os/Codex-sibling
# import, Stage 3) has real installable SKILL.md content in skills-library/. Install up
# to a hard cap so a project never gets hundreds of skills loaded at session start -
# Claude Code scans name+description for every installed skill (~100 tokens each) even
# when unused, so capping here is a real context-budget decision, not cosmetic.
# Matched independently against skills-library/index.json (not against $candidates, the
# capped-at-40 general text candidate list) - the cap is easily saturated by a
# high-frequency tag like "web"/"frontend" before ever reaching a less-common tag like
# "3d", which would silently starve skill installation for exactly the projects most
# likely to want it. Found by testing a package.json with react-three-fiber: the general
# candidate list was 100% "web"-tagged entries, zero 3d-tagged ones made the top 40.
skill_install_cap=20
skills_lib_index="$HOME/.claude/templates/claude-md-os/skills-library/index.json"
installed_count=0
if [ -f "$skills_lib_index" ] && command -v jq >/dev/null 2>&1; then
  lib_root="$HOME/.claude/templates/claude-md-os/skills-library"
  # jq on Windows/Git Bash emits CRLF; a trailing \r on a skill name would break every
  # downstream path lookup (a file "name\r" never exists). Same fix pattern already
  # used throughout run-evals.sh (there via a local strip_cr() helper) for identical
  # jq-output-on-Windows drift.
  tags_json="$(printf '%s\n' "${tags[@]}" | jq -R . | jq -s . | tr -d '\r')"
  to_install=()
  while IFS= read -r nm; do
    [ -z "$nm" ] && continue
    [ "${#to_install[@]}" -ge "$skill_install_cap" ] && break
    to_install+=("$nm")
  done < <(jq -r --argjson tags "$tags_json" '
    to_entries[] | select((.value.tags // []) as $st | ($tags - ($tags - $st)) | length > 0) | .key
  ' "$skills_lib_index" | tr -d '\r')

  if [ "${#to_install[@]}" -gt 0 ]; then
    skills_dir="$target/.claude/skills"
    mkdir -p "$skills_dir"
    for nm in "${to_install[@]}"; do
      src_md="$lib_root/$nm/SKILL.md"
      [ -f "$src_md" ] || continue
      dest_dir="$skills_dir/$nm"
      mkdir -p "$dest_dir"
      cp "$src_md" "$dest_dir/SKILL.md"
      installed_count=$((installed_count + 1))
    done
  fi
fi

echo "PROFILE.lock: $lock"
echo "  tags: $tags_csv | candidates: $cand_count | skills installed: $installed_count"
