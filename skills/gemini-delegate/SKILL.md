---
name: gemini-delegate
description: Delegate a self-contained task to Google Gemini CLI as an extra worker beside normal subagents. Use when a task is well-specified, bounded, and can run headless (implementation, tests, docs, reviews, research), and the Gemini CLI is installed and signed in. Follow the delegate-skills level (low, medium, ultra) given in session context.
---

# gemini-delegate

Run `gemini` headless as a worker. Claude stays orchestrator and reviewer.

## Delegation level

Set with `/delegate low|medium|ultra` (default `medium`); a SessionStart hook prints the saved level into each session.

- `low`: delegate only when the user explicitly asks.
- `medium`: delegate when the task fits the rules below.
- `ultra`: prefer delegating over Claude subagents and over doing the work yourself. Delegate anything a worker can do; keep orchestration, review and work no worker can do. Fall back only when gates block or the worker fails.

## Gate (automatic)

`gemini-run.ps1` first runs `gemini-gate.ps1`. It blocks (exit 3, `GATE_BLOCKED: <why>`) if `gemini` is missing or the part is disabled. If blocked, use a normal Claude subagent instead. `GEMINI_AUTH` means the user must run `gemini` once and sign in; never try to log in yourself. `GEMINI_LIMIT` means quota is exhausted; fall back, do not retry.

## Model

Gemini CLI's default model is used. Pass `-Model <id>` when you decide the task needs a specific model (for example a faster flash model for mechanical work).

## How

The scripts sit next to this SKILL.md; use this skill's base directory as `<skill dir>`:

```powershell
& "<skill dir>\gemini-run.ps1" -Prompt "<task>" -Cwd "<project dir>" [-Model <id>] [-Write] [-TimeoutSec 900]
```

- Default is read-only (`--approval-mode plan`).
- `-Write` uses `--approval-mode yolo`: Gemini may run commands and edit files. Use only on a git repo you can diff, never with secrets in the prompt.
- `--skip-trust` is always passed so headless runs work in untrusted folders.
- Long jobs: run with `run_in_background` and wait for the notification.
- Output starts with `model=<id|default>` then Gemini's reply.

## Prompt template

Gemini has no access to this conversation. Include: goal, files in scope and out of scope, conventions (point at an example file), done criteria with a verify command, and "Do not commit. Report changed files and anything unverified."

## After Gemini returns (mandatory)

1. Read `git diff` / `git status`.
2. Re-run the verify command yourself.
3. Fix small issues directly; re-delegate or take over for big misses.
4. Tell the user what Gemini did and what you verified.

## Notes

- Install: `npm install -g @google/gemini-cli`, then run `gemini` once to sign in (Google login or `GEMINI_API_KEY`).
