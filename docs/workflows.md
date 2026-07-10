# Workflows

## Daily project workflow

1. Open a project with SREDNOFF OS deployed. `CLAUDE.md` + `.claude/rules/00-90` load
   automatically; the `SessionStart` banner (if wired) shows a one-line active/tags/rules
   summary.
2. If `.claude/PROFILE.lock.md` exists, read it before the first edit (enforced by
   `require-profile-lock-read` when the hook is active).
3. For substantial work, run `mode-router` + `domain-router` + `select-skills` (rule 70)
   rather than guessing a skill set from memory.
4. For UI/3D/design/growth source decisions, run `source-ranker` against
   `design-source-registry.json` before picking a component library or asset source.
5. Implement, validate, commit.

## Bringing a project up to date (sync)

A project initialized under an older OS version doesn't auto-update. `doctor`'s
`template-drift` check compares the project's `PROFILE.lock.md` version stamp against
the current template and warns (never fails) when they diverge. To refresh:

```powershell
& "$env:USERPROFILE\.claude\templates\claude-md-os\scripts\apply-os-all.ps1" "G:\path\to\workspace" -Sync
```

`-Sync` (default off, backward-compatible) re-runs `init-claude-project` on
already-initialized projects, not just missing ones - hash-diffing, timestamped backups,
and `CLAUDE.md` preservation all apply exactly as they do for a first-time init, since
`-Sync` is a thin flag over the same script, not a separate code path.

## System maintenance

Health check, any project:

```powershell
& "$env:USERPROFILE\.claude\templates\claude-md-os\scripts\doctor.ps1" -ProjectPath "<path>" -RunEvals -FixSafe
```

Reports structure, registry integrity (0 duplicates expected), catalog format, catalog
JSON sync, skills-library metadata validity, template drift, hook canary (feeds each
security hook known-bad input and confirms it still denies), and eval pass rate - then
safely repairs what it can with `-FixSafe`.

## Release checkpoint workflow

This project maintains a private source of truth
(`~/.claude/templates/claude-md-os` + `~/.claude/registry`, both individually
git-versioned) and a redacted public mirror
(github.com/srednoff888-art/srednoff-os-for-claude). A release checkpoint:

1. Make the change in the private source; test on both PowerShell and bash.
2. Run `doctor -RunEvals` on the template root; confirm green (or only the expected,
   pre-existing WARN for the template not being a "project").
3. Commit the private repos (or let `doctor`'s auto-commit safety net capture it).
4. Copy the changed/new files into the staging clone of the public repo.
5. **Sweep for private names and secrets before committing the staging clone** - this
   step has caught real leaks in this project's history and is not optional.
6. Commit and push the public repo.
7. Poll `gh run list`/`gh run view` until the real GitHub Actions run completes; confirm
   every job green before considering the checkpoint done. A local pass is not
   sufficient evidence on its own - this project has caught real CI-only failures
   (Windows-specific PowerShell bugs, a bash-3.2-only regression) that never reproduced
   locally.
8. Update `registry/CHANGELOG.md` and `registry/version.json` in the same checkpoint,
   not as an afterthought.

## TURBO boundaries

`TURBO` activates only on the literal word "TURBO" from the user - synonyms like
"maximally", "don't skimp on tokens", or "production launch" map to `critical`/
`production` mode, never `turbo` (rule 80, `quality-modes.json`). TURBO raises the
selection budget; it does not bypass destructive-action confirmation, secret handling,
or license review.
