# SREDNOFF OS for Claude

**An engineering-discipline operating system for [Claude Code](https://claude.com/claude-code).**
Drop it into any repo and Claude stops improvising — it follows rules, picks the right skill for the job from a curated registry of 2000+ options, routes to the right model tier, and gets stopped by hooks before it leaks a secret or runs `rm -rf`.

[Русская версия ниже / Russian version below](README.ru.md)

---

## Why this exists

Out of the box, Claude Code is extremely capable — but every session starts from a blank slate. It re-decides your engineering standards every time, has no memory of which skill actually helped last time, and has no safety net if it (or you) types something dangerous into a terminal.

SREDNOFF OS is a layer of files that fixes that:

- **Rules, not vibes.** A `CLAUDE.md` + `.claude/rules/` stack that encodes how you want work done — code review standards, model routing, subagent contracts — so every session starts already aligned.
- **2000+ skills/agents, one selector.** A curated, deduplicated registry (`CORE-300.md`) pulled from official Anthropic sources, VoltAgent, wshobson, and other vetted collections, organized into three token-cost tiers (cheap/balanced/deep) with a scoring selector that picks what a task actually needs — never downgrading quality just to save tokens.
- **Security hooks that actually fire.** PowerShell hooks that scan every Bash command, file write, and prompt for secrets (Stripe, AWS, GitHub, Anthropic, Slack, npm, and more) and dangerous patterns (`rm -rf`, `mkfs`, `git push --force`, `format C:`) — and **deny** before the tool runs, not after.
- **A doctor, not just docs.** One script (`doctor.ps1`) checks structure, runs eval fixtures, feeds hooks known-bad synthetic input to catch silent regressions, and auto-commits the registry to git so a bad edit is always revertible.
- **Built to be honest with itself.** This system was stress-tested by asking Claude to critique it as a hostile, maximally-informed adversary — the gaps that review found (hooks that had never fired outside manual tests, 30% of catalog entries tagged only `[general]`, zero version control on a 2000-record catalog) are the reasons several of the components below exist.

## What's in the box

```
CLAUDE.md, AGENTS.md, code_review.md   — the core rulebook
.claude/rules/00-90                     — 10 numbered rule files (skill selection, model routing, subagent contract...)
.claude/skills/                         — reusable skill definitions
.claude/commands/                       — slash commands
.claude/hooks/                          — PowerShell + Bash hooks (secret scanning, dangerous-command blocking)
.agent/                                 — agent-facing conventions
scripts/                                — install, doctor, profile-lock generator, eval runner
registry/CORE-300.md                    — 2000+ skills/agents, tagged and tiered
registry/SELECTION-PROTOCOL.md          — how to pick skills for a project without loading the whole catalog
registry/CAPABILITY-INDEX.md            — one canonical pick per capability (no overlap confusion)
registry/evals/                         — fixtures that catch regressions in routing and secret detection
scripts/global/                         — optional global SessionStart hook + statusline (opt-in, see below)
```

## Install

Requires Windows PowerShell 5.1+ (the hooks and scripts are `.ps1`; `.sh` equivalents are included for the structural/install scripts where it mattered).

**Per project:**
```powershell
& "path\to\srednoff-os\scripts\init-claude-project.ps1" "C:\path\to\your\project"
```
This copies the rulebook into your project, generates a `.claude/PROFILE.lock.md` tailored to what it detects in your repo (Next.js? Python? trading/backtest code? Amazon FBA?), and never overwrites a `CLAUDE.md` you already have — it backs up and merges instead.

**Health check anytime:**
```powershell
& "path\to\srednoff-os\scripts\doctor.ps1" -ProjectPath "C:\path\to\your\project" -RunEvals -FixSafe
```
Reports structure status, registry integrity, eval pass rate, and runs a live canary test against your security hooks — then safely repairs anything missing.

**Global auto-apply (optional, opt-in):** `scripts/global/session-start-hook.ps1` and `scripts/global/statusline.ps1` can be wired into `~/.claude/settings.json` to auto-detect and announce the OS at the start of every session under a workspace root you control via the `SREDNOFF_OS_ROOT` environment variable (defaults to your home directory if unset). See the hooks' own comments for the exact `settings.json` keys.

## Security hooks are opt-in, on purpose

Nothing here modifies your global Claude Code settings by default. Hook wiring examples live in `.claude/settings.example.json` — copy the relevant block in yourself once you've read what it does. The registry and rules are safe to drop in immediately; hooks that can block tool calls are something you should consciously turn on.

## The core idea, in one line

**Quality of the solution comes first. Economy is only a tie-breaker.** Every routing rule in this system exists to pick the *right* tool for a task, not the *cheapest* one — cost-awareness only kicks in when two options would deliver the same result.

## License

MIT — see [LICENSE](LICENSE). Use it, fork it, strip it down, build on it.
