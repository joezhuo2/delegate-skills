---
name: qwen-delegate
description: Delegate a self-contained task to Qwen Code CLI as an extra worker beside normal subagents. Use when a task is well-specified, bounded, and can run headless (implementation, tests, docs, reviews, research), and Qwen Code is installed and signed in. Follow the delegate-skills level (low, medium, ultra) given in session context.
---

# qwen-delegate

Run `qwen` headless as a worker. Claude stays orchestrator and reviewer.

## Delegation level

Set with `/delegate low|medium|ultra` (default `medium`); a SessionStart hook prints the saved level into each session.

- `low`: delegate only when the user explicitly asks.
- `medium`: delegate when the task fits the rules below.
- `ultra`: prefer delegating over Claude subagents and over doing the work yourself. Delegate anything a worker can do; keep orchestration, review and work no worker can do. Fall back only when gates block or the worker fails.

## Gate (automatic)

`qwen-run.ps1` first runs `qwen-gate.ps1`. It blocks (exit 3, `GATE_BLOCKED: <why>`) if `qwen` is missing or the part is disabled. If blocked, use a normal Claude subagent instead. `QWEN_AUTH` means the user must run `qwen` once and sign in; never try to log in yourself. `QWEN_LIMIT` means quota is exhausted; fall back, do not retry.

## Model

Qwen Code's default model is used. Pass `-Model <id>` when you decide the task needs a specific model.

## How

The scripts sit next to this SKILL.md; use this skill's base directory as `<skill dir>`:

```powershell
& "<skill dir>\qwen-run.ps1" -Prompt "<task>" -Cwd "<project dir>" [-Model <id>] [-Write] [-TimeoutSec 900]
```

- Default is read-only (`--approval-mode plan`).
- `-Write` uses `--approval-mode yolo`: Qwen may run commands and edit files. Use only on a git repo you can diff, never with secrets in the prompt.
- Long jobs: run with `run_in_background` and wait for the notification.
- Output starts with `model=<id|default>` then Qwen's reply.

## Prompt template

Qwen has no access to this conversation. Include: goal, files in scope and out of scope, conventions (point at an example file), done criteria with a verify command, and "Do not commit. Report changed files and anything unverified."

## After Qwen returns (mandatory)

1. Read `git diff` / `git status`.
2. Re-run the verify command yourself.
3. Fix small issues directly; re-delegate or take over for big misses.
4. Tell the user what Qwen did and what you verified.

## Notes

- Install: `npm install -g @qwen-code/qwen-code`, then run `qwen` once to sign in or pick an auth type (headless runs fail with "No auth type is selected" until then).
