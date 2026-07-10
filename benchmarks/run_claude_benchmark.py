#!/usr/bin/env python3
"""Reproducible clean-Claude-Code versus SREDNOFF OS benchmark runner.

Ported from srednoff-os (Codex sibling)'s run_codex_benchmark.py - concept,
task set, oracle design, and validity rules carried over; the CLI invocation
layer is rewritten for `claude` (verified against code.claude.com/docs/en/cli-reference
and /en/headless before writing, not guessed):
  - control arm: `claude -p --bare` - skips CLAUDE.md, hooks, skills, plugins,
    MCP servers, and auto-memory entirely, so it cannot inherit SREDNOFF OS by
    accident (the exact failure mode this harness's validity check guards against).
  - os arm: a real SREDNOFF OS deployment (init-claude-project.ps1) in the
    workspace, then `claude -p` (no --bare) so CLAUDE.md/rules/hooks/skills load
    normally - the actual, real product being measured, not a one-line stand-in.
  - `--output-format json` for session_id + total_cost_usd + per-model cost.
  - `--permission-mode acceptEdits --allowedTools "Read,Edit,Bash"` instead of
    `--dangerously-skip-permissions`/bypassPermissions: acceptEdits auto-approves
    file writes and common filesystem commands but still requires an
    --allowedTools entry for anything else (network, unlisted shell patterns) -
    a meaningfully safer default for an unattended script than a full bypass.
  - `--continue` for turn 2+ instead of codex's `resume --last`.

The generated task workspaces are intentionally outside this repository. That
keeps the control arm from inheriting a stray CLAUDE.md if one existed nearby.

NOTE: this script has been written and reasoned through but NOT executed end to
end - a real run costs real API tokens across (tasks x arms x repeats) turns
and takes real wall-clock time. Run it deliberately, not as part of routine CI.
See README.md in this directory for how to run a small pilot first.
"""

from __future__ import annotations

import argparse
import importlib.util
import json
import os
import re
import shutil
import subprocess
import sys
import time
from dataclasses import dataclass
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parent
DEFAULT_OUTPUT = ROOT.parent.parent.parent / "claude-os-benchmark-runs"
ARMS = ("control", "srednoff_os")
PROHIBITED = {
    "eval": r"\beval\s*\(",
    "exec": r"\bexec\s*\(",
    "shell_true": r"shell\s*=\s*True",
    "pickle_load": r"\bpickle\.loads?\s*\(",
}

# init-claude-project.ps1 lives in the parent scripts/ dir of this template checkout.
INIT_SCRIPT = ROOT.parent / "scripts" / "init-claude-project.ps1"


@dataclass(frozen=True)
class Task:
    task_id: str
    title: str
    function: str
    signature: str
    prompt: str
    cases: list[tuple[Any, ...]]
    expected: list[Any]


# Same deterministic algorithmic corpus as the donor harness - generic CS
# problems, not language/tool specific, so they carry over unchanged.
TASKS = [
    Task("longest_unique_substring", "Longest substring without repeating characters", "length_of_longest_substring", "def length_of_longest_substring(value: str) -> int:", "Return the length of the longest contiguous substring with no repeated characters. Handle an empty string.", [("abcabcbb",), ("bbbbb",), ("pwwkew",), ("",), ("dvdf",)], [3, 1, 3, 0, 3]),
    Task("product_except_self", "Product of array except self", "product_except_self", "def product_except_self(values: list[int]) -> list[int]:", "Return products of all values except the one at each index. Do not use division. Support zeros and negative integers.", [([1, 2, 3, 4],), ([0, 1, 2, 3],), ([0, 0, 3],), ([-1, 1, -1, 1],)], [[24, 12, 8, 6], [6, 0, 0, 0], [0, 0, 0], [-1, 1, -1, 1]]),
    Task("three_sum", "Three sum", "three_sum", "def three_sum(values: list[int]) -> list[list[int]]:", "Return every unique triple whose sum is zero. Each triple and the outer result must be deterministically sorted.", [([-1, 0, 1, 2, -1, -4],), ([0, 1, 1],), ([0, 0, 0, 0],)], [[[-1, -1, 2], [-1, 0, 1]], [], [[0, 0, 0]]]),
    Task("course_schedule", "Course schedule", "can_finish", "def can_finish(course_count: int, prerequisites: list[list[int]]) -> bool:", "Return whether all courses can be completed. Each pair [course, prerequisite] means prerequisite must precede course.", [(2, [[1, 0]]), (2, [[1, 0], [0, 1]]), (4, [[1, 0], [2, 1], [3, 2]])], [True, False, True]),
    Task("number_of_islands", "Number of islands", "num_islands", "def num_islands(grid: list[list[str]]) -> int:", "Return the number of 4-directionally connected islands of '1' cells. Do not mutate the caller's grid.", [([['1','1','0','0'], ['1','0','0','1'], ['0','0','1','1']],), ([['0','0'], ['0','0']],), ([],)], [2, 0, 0]),
    Task("word_break", "Word break", "word_break", "def word_break(value: str, words: list[str]) -> bool:", "Return whether value can be segmented into one or more dictionary words. Treat an empty input as segmentable.", [("leetcode", ["leet", "code"]), ("applepenapple", ["apple", "pen"]), ("catsandog", ["cats", "dog", "sand", "and", "cat"]), ("", ["a"])], [True, True, False, True]),
    Task("daily_temperatures", "Daily temperatures", "daily_temperatures", "def daily_temperatures(values: list[int]) -> list[int]:", "For each temperature, return days until a strictly warmer future temperature, or zero if none exists.", [([73,74,75,71,69,72,76,73],), ([30,40,50,60],), ([30,60,90],), ([90,80,70],)], [[1,1,4,2,1,1,0,0], [1,1,1,0], [1,1,0], [0,0,0]]),
    Task("top_k_frequent", "Top K frequent elements", "top_k_frequent", "def top_k_frequent(values: list[int], k: int) -> list[int]:", "Return the k most frequent values. Break equal-frequency ties by smaller numeric value first, so output is deterministic.", [([1,1,1,2,2,3], 2), ([4,4,1,1,2,2,3], 3), ([-1,-1,2,2,3], 2)], [[1,2], [1,2,4], [-1,2]]),
    Task("minimum_window", "Minimum window substring", "min_window", "def min_window(source: str, target: str) -> str:", "Return the shortest substring of source containing every target character with multiplicity. Return an empty string when impossible.", [("ADOBECODEBANC", "ABC"), ("a", "a"), ("a", "aa"), ("aa", "aa")], ["BANC", "a", "", "aa"]),
]

CLI_TASK_ID = "log_metrics_cli"
CLI_TASK_PROMPT = """Create a dependency-free Python CLI named log_metrics.py and tests.

Usage: python log_metrics.py <path-to-log>
Each non-empty line has the form: ISO_TIMESTAMP LEVEL message text. LEVEL is one
of DEBUG, INFO, WARN, ERROR. Ignore malformed lines. Print one JSON object to
stdout with keys total, levels (all four levels in that order-independent map),
first_timestamp, and last_timestamp. Timestamps must be compared lexically.
Never use shell commands, eval, external packages, or write files beside tests.
Exit 2 and print a concise error to stderr when the input file does not exist.
"""


def write_task(workspace: Path, task_id: str) -> None:
    workspace.mkdir(parents=True, exist_ok=True)
    if task_id == CLI_TASK_ID:
        (workspace / "TASK.md").write_text(CLI_TASK_PROMPT, encoding="utf-8", newline="\n")
        return
    task = next(task for task in TASKS if task.task_id == task_id)
    (workspace / "TASK.md").write_text(
        f"# {task.title}\n\n{task.prompt}\n\nImplement only `{task.function}` in `solution.py`. "
        "Use Python standard library only and add useful tests if they help you.\n",
        encoding="utf-8", newline="\n",
    )
    (workspace / "solution.py").write_text(
        f"{task.signature}\n    raise NotImplementedError\n", encoding="utf-8", newline="\n"
    )


def deploy_srednoff_os(workspace: Path) -> None:
    """OS arm setup: a REAL deployment via init-claude-project.ps1, not a
    stand-in instruction file - this measures the actual product."""
    if not INIT_SCRIPT.exists():
        raise FileNotFoundError(f"init-claude-project.ps1 not found: {INIT_SCRIPT}")
    subprocess.run(
        ["powershell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", str(INIT_SCRIPT), str(workspace)],
        check=True, capture_output=True, text=True, timeout=60,
    )


def run_oracle(workspace: Path, task_id: str) -> tuple[bool, str, int]:
    started = time.perf_counter()
    if task_id == CLI_TASK_ID:
        sample = workspace / "hidden-sample.log"
        sample.write_text(
            "2026-07-01T10:00:00Z INFO boot\ninvalid\n2026-07-01T10:02:00Z ERROR boom\n2026-07-01T10:01:00Z WARN warm\n",
            encoding="utf-8", newline="\n",
        )
        completed = subprocess.run(
            [sys.executable, "log_metrics.py", str(sample)], cwd=workspace, text=True,
            capture_output=True, timeout=20,
        )
        if completed.returncode != 0:
            return False, f"cli_exit={completed.returncode}; stderr={completed.stderr[-500:]}", int((time.perf_counter() - started) * 1000)
        try:
            result = json.loads(completed.stdout)
        except json.JSONDecodeError as error:
            return False, f"invalid_json={error}", int((time.perf_counter() - started) * 1000)
        expected = {"total": 3, "levels": {"DEBUG": 0, "INFO": 1, "WARN": 1, "ERROR": 1}, "first_timestamp": "2026-07-01T10:00:00Z", "last_timestamp": "2026-07-01T10:02:00Z"}
        return result == expected, "ok" if result == expected else f"expected={expected}; actual={result}", int((time.perf_counter() - started) * 1000)

    task = next(task for task in TASKS if task.task_id == task_id)
    source = workspace / "solution.py"
    if not source.exists():
        return False, "solution.py missing", int((time.perf_counter() - started) * 1000)
    try:
        spec = importlib.util.spec_from_file_location("candidate_solution", source)
        module = importlib.util.module_from_spec(spec)
        assert spec and spec.loader
        spec.loader.exec_module(module)
        candidate = getattr(module, task.function)
        actual = [candidate(*args) for args in task.cases]
    except Exception as error:  # Oracle error is a measured runtime/API defect.
        return False, f"{type(error).__name__}: {error}", int((time.perf_counter() - started) * 1000)
    return actual == task.expected, "ok" if actual == task.expected else f"expected={task.expected!r}; actual={actual!r}", int((time.perf_counter() - started) * 1000)


def scan_security(workspace: Path) -> list[str]:
    findings: list[str] = []
    for path in workspace.rglob("*.py"):
        if path.name.startswith("hidden-"):
            continue
        text = path.read_text(encoding="utf-8", errors="replace")
        for rule, pattern in PROHIBITED.items():
            if re.search(pattern, text):
                findings.append(f"{path.name}:{rule}")
    return findings


def claude_command(model: str, prompt: str, bare: bool, resume: bool) -> list[str]:
    base = ["claude", "-p", "--output-format", "json",
            "--permission-mode", "acceptEdits", "--allowedTools", "Read,Edit,Bash"]
    if bare:
        base = base + ["--bare"]
    if resume:
        return base + ["--continue", prompt]
    return base + ["--model", model, prompt]


def execute_turn(workspace: Path, model: str, prompt: str, bare: bool, resume: bool) -> dict[str, Any]:
    command = claude_command(model, prompt, bare, resume)
    try:
        completed = subprocess.run(
            command, cwd=workspace, text=True, encoding="utf-8", errors="replace",
            capture_output=True, timeout=600,
        )
    except subprocess.TimeoutExpired:
        return {"exit_code": 124, "stderr": "claude invocation timed out", "session_id": None,
                "total_cost_usd": None, "raw_stdout_tail": ""}
    stdout = (completed.stdout or "").strip()
    parsed: dict[str, Any] = {}
    if stdout:
        try:
            parsed = json.loads(stdout)
        except json.JSONDecodeError:
            parsed = {}
    return {
        "exit_code": completed.returncode,
        "stderr": (completed.stderr or "")[-1000:],
        "session_id": parsed.get("session_id"),
        "total_cost_usd": parsed.get("total_cost_usd"),
        "raw_stdout_tail": stdout[-2000:],
    }


def run_one(output: Path, arm: str, task_id: str, replicate: int, model: str, max_turns: int) -> dict[str, Any]:
    workspace = output / "workspaces" / arm / task_id / f"run-{replicate:02d}"
    if workspace.exists():
        shutil.rmtree(workspace)
    write_task(workspace, task_id)
    bare = arm == "control"
    if arm == "srednoff_os":
        deploy_srednoff_os(workspace)
    initial_prompt = "Read TASK.md, implement the requested solution in this workspace, and validate it locally. Do not use network or external packages."
    started = time.perf_counter()
    total_cost = 0.0
    cost_seen = False
    attempts: list[dict[str, Any]] = []
    green = False
    first_pass = False
    oracle_detail = "not run"
    for turn in range(1, max_turns + 1):
        prompt = initial_prompt if turn == 1 else f"The independent hidden oracle failed: {oracle_detail}. Fix the root cause, then validate locally."
        turn_result = execute_turn(workspace, model, prompt, bare, resume=turn > 1)
        if turn_result.get("total_cost_usd") is not None:
            total_cost += float(turn_result["total_cost_usd"])
            cost_seen = True
        passed, oracle_detail, oracle_ms = run_oracle(workspace, task_id)
        attempts.append({"turn": turn, "exit_code": turn_result["exit_code"], "stderr": turn_result["stderr"],
                          "session_id": turn_result["session_id"], "oracle_pass": passed,
                          "oracle_detail": oracle_detail, "oracle_ms": oracle_ms})
        if passed:
            green = True
            first_pass = turn == 1
            break
    elapsed_s = round(time.perf_counter() - started, 3)
    invalid_reasons: list[str] = []
    if arm == "control":
        # A CLAUDE.md or rules file appearing in the control workspace would mean
        # --bare somehow didn't isolate the run - this must never happen, and if
        # it does, the run is invalid rather than silently counted.
        if (workspace / "CLAUDE.md").exists() or (workspace / ".claude" / "rules").exists():
            invalid_reasons.append("control workspace has SREDNOFF OS files - --bare isolation failed")
    return {
        "arm": arm, "task_id": task_id, "replicate": replicate, "model": model,
        "valid": not invalid_reasons, "invalid_reasons": invalid_reasons,
        "green": green, "first_pass": first_pass, "turns_to_green": len(attempts) if green else None,
        "attempts": attempts, "elapsed_seconds": elapsed_s,
        "total_cost_usd": total_cost if cost_seen else None,
        "security_findings": scan_security(workspace),
        "hallucinated_or_runtime_defects": sum(1 for attempt in attempts if not attempt["oracle_pass"]),
        "workspace": str(workspace),
    }


def render_report(records: list[dict[str, Any]]) -> str:
    rows = ["| Arm | Runs | First-pass | Green | Avg turns to green | Avg seconds to green | Security findings | Avg cost (USD) |", "|---|---:|---:|---:|---:|---:|---:|---:|"]
    for arm in ARMS:
        group = [record for record in records if record["arm"] == arm]
        if not group:
            continue
        invalid = [record for record in group if not record.get("valid", True)]
        valid = [record for record in group if record.get("valid", True)]
        if not valid:
            rows.append(f"| {arm} | {len(group)} | invalid ({len(invalid)}/{len(group)}) | invalid | n/a | n/a | n/a | n/a |")
            continue
        first = sum(record["first_pass"] for record in valid) / len(valid) * 100
        green = sum(record["green"] for record in valid) / len(valid) * 100
        turns = [record["turns_to_green"] for record in valid if record["turns_to_green"] is not None]
        times = [record["elapsed_seconds"] for record in valid if record["green"]]
        findings = sum(len(record["security_findings"]) for record in valid)
        cost_values = [record["total_cost_usd"] for record in valid if record["total_cost_usd"] is not None]
        cost_cell = f"${sum(cost_values) / len(cost_values):.4f}" if cost_values else "not exposed"
        turns_cell = f"{sum(turns) / len(turns):.2f}" if turns else "n/a"
        time_cell = f"{sum(times) / len(times):.2f}" if times else "n/a"
        rows.append(f"| {arm} | {len(group)} ({len(invalid)} invalid) | {first:.1f}% | {green:.1f}% | {turns_cell} | {time_cell} | {findings} | {cost_cell} |")
    return "\n".join(rows) + "\n"


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--model", required=True, help="Frozen model id used by both arms, e.g. sonnet or claude-sonnet-5")
    parser.add_argument("--repeats", type=int, default=3, choices=range(3, 6))
    parser.add_argument("--tasks", nargs="*", default=[task.task_id for task in TASKS] + [CLI_TASK_ID])
    parser.add_argument("--max-turns", type=int, default=3, choices=range(1, 5))
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    parser.add_argument("--arms", nargs="*", default=list(ARMS), choices=ARMS)
    args = parser.parse_args()
    known = {task.task_id for task in TASKS} | {CLI_TASK_ID}
    unknown = sorted(set(args.tasks) - known)
    if unknown:
        parser.error(f"Unknown tasks: {', '.join(unknown)}")
    output = args.output.resolve()
    output.mkdir(parents=True, exist_ok=True)
    metadata = {"runner": "v1-claude", "model": args.model, "repeats": args.repeats, "tasks": args.tasks,
                "arms": args.arms, "python": sys.version, "started_at": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())}
    (output / "metadata.json").write_text(json.dumps(metadata, indent=2), encoding="utf-8", newline="\n")
    records: list[dict[str, Any]] = []
    for arm in args.arms:
        for task_id in args.tasks:
            for replicate in range(1, args.repeats + 1):
                print(f"RUN arm={arm} task={task_id} replicate={replicate}", flush=True)
                record = run_one(output, arm, task_id, replicate, args.model, args.max_turns)
                records.append(record)
                (output / "results.json").write_text(json.dumps(records, indent=2), encoding="utf-8", newline="\n")
    report = render_report(records)
    (output / "REPORT.md").write_text(report, encoding="utf-8", newline="\n")
    print(report)
    if any(record["total_cost_usd"] is None for record in records):
        print("WARNING: CLI output did not expose total_cost_usd for at least one run; cost comparison is intentionally omitted for those runs.", file=sys.stderr)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
