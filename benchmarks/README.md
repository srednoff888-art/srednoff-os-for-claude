# Reproducible Claude Code Benchmark

This benchmark measures a clean Claude Code control against the SREDNOFF OS
policy arm. It deliberately does not call the control arm "raw" unless it meets
all of the conditions below. Ported from srednoff-os (the Codex sibling)'s
`run_codex_benchmark.py` - same task corpus, same oracle/validity design,
CLI invocation layer rewritten for `claude` (verified against
[the official CLI reference](https://code.claude.com/docs/en/cli-reference) and
[headless docs](https://code.claude.com/docs/en/headless) before writing).

**Status: written and reasoned through, not yet executed end to end.** A real
run spends real API budget across `tasks x arms x repeats` turns and takes real
wall-clock time - it is not part of routine CI and should be run deliberately.
The oracle scoring, security scan, and OS-arm deployment logic have been
smoke-tested in isolation (no API calls); the actual `claude -p` invocation
path has not.

## What is controlled

- identical model, CLI version, task prompt, time limit, and machine;
- a fresh workspace for every `task x arm x replicate` run;
- hidden, deterministic Python oracles that are outside the agent workspace;
- **control arm**: `claude -p --bare` - skips CLAUDE.md, hooks, skills,
  plugins, MCP servers, and auto-memory entirely (confirmed via official docs,
  not assumed), so it cannot inherit SREDNOFF OS by accident;
- **OS arm**: a *real* SREDNOFF OS deployment (`init-claude-project.ps1` run
  against the workspace, same script real projects use) - this measures the
  actual product, not a one-line stand-in instruction file;
- results.json + REPORT.md retained under the run output directory.

The corpus is nine medium algorithmic tasks (LeetCode-style, deterministic
oracle) plus one reproducible CLI task, identical to the donor's set - the
tasks themselves are generic CS problems, not Codex-specific.

## Metrics

| Metric | Definition |
|---|---|
| First-pass success | Hidden oracle passes immediately after the initial agent turn. |
| Turns to green | Initial turn plus resumptions after an oracle failure; capped by `--max-turns`. |
| Security findings | Static prohibited-pattern findings (`eval`, `exec`, `shell=True`, `pickle.loads`) in generated `.py` files. |
| Cost (USD) | `total_cost_usd` from `--output-format json`, summed across turns. Confirmed present in the response payload by the official headless docs. |
| Time to green | Wall time from the initial call until the hidden oracle first passes. |

An unsuccessful run is not silently dropped. It remains in the aggregate with
`first_pass=false`, `green=false`, and its real elapsed time.

## Permission posture

The runner uses `--permission-mode acceptEdits --allowedTools "Read,Edit,Bash"`,
**not** `--dangerously-skip-permissions`/`bypassPermissions`. `acceptEdits`
auto-approves file writes and common filesystem commands but still requires an
explicit `--allowedTools` entry for anything else (network requests, unlisted
shell patterns) - a meaningfully safer default for an unattended script than a
full permission bypass, at the cost of the run aborting if a task genuinely
needs a tool outside that list. The benchmark tasks are scoped (stdlib-only,
no network) specifically so this restriction doesn't interfere with them.

## Run a pilot

From the repository root:

```powershell
python benchmarks/run_claude_benchmark.py --model sonnet --repeats 3 --tasks log_metrics_cli
```

Run the complete algorithmic corpus:

```powershell
python benchmarks/run_claude_benchmark.py --model sonnet --repeats 3
```

Results are written outside this repository by default (`../../../claude-os-benchmark-runs`),
so the control workspace cannot inherit this repository's own `CLAUDE.md`.

## Validity rules

- Do not compare different models, CLI versions, permission modes, or machines.
- A control-arm workspace containing `CLAUDE.md` or `.claude/rules/` after the
  run is invalid and excluded from the aggregate (`--bare` isolation failure) -
  checked automatically, not by eyeballing the transcript.
- Do not use model self-reports as a correctness signal - only the hidden
  oracle's exit determines pass/fail.
- Do not aggregate runs that terminated because auth, network, or the runner
  itself failed; record them as invalid instead.
- Review every green diff for prohibited patterns before publishing a claim
  (the security scan is a floor, not a substitute for review).

The runner prints an explicit warning if `total_cost_usd` was absent from any
run's output; cost comparison is omitted for those runs rather than silently
treated as zero.
