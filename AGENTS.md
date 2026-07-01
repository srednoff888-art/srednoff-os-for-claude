# AGENTS.md — Agent Interop Instructions

This repository is primarily configured for Claude Code through `CLAUDE.md`.

If you are another coding agent (Codex, Cursor, Gemini, etc.), follow the same core rules:

- read `CLAUDE.md`;
- use `.agent/` workflow files;
- use `.claude/rules/` as modular rules;
- perform GitHub research before non-trivial work;
- ask at most 5 blocking questions;
- do not overwrite existing work;
- do not perform destructive actions without explicit user approval;
- run tests/build/lint before final response when possible.

Main instruction file:

```md
@CLAUDE.md
```
