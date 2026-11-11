---
name: claude-delegate
description: Route a task to a native Claude subagent on the model that fits it (Haiku, Sonnet, Opus or Fable), and decide between a Claude subagent and the external delegate workers (Codex, Kiro, Gemini, Qwen, Copilot). Use whenever you are about to hand off work or spawn a subagent. Follow the delegate-skills level (low, medium, ultra) given in session context.
---

# claude-delegate

Spawn a Claude subagent with the Agent tool on the cheapest model that can do the task well. Claude stays orchestrator and reviewer, and decides per task which worker gets it.

## Delegation level

Set with `/delegate low|medium|ultra` (default `medium`); a SessionStart hook prints the saved level and the enabled workers into each session.

- `low`: delegate only when the user explicitly asks.
- `medium`: delegate when the task fits the rules below.
- `ultra`: prefer delegating over doing the work yourself. Delegate anything a worker can do; keep orchestration, review and work no worker can do.

If `claude` is not in the enabled list, this part is disabled: do not use this skill's routing.

## Choose the worker

You are the orchestrator. For each task, pick one:

| Task | Worker |
| --- | --- |
| Needs this conversation's context, back-and-forth, or tools only this session has | Claude subagent (or yourself) |
| Self-contained, bounded, verifiable with one command, no conversation context needed | An enabled external worker (`codex-delegate`, `kiro-delegate`, `gemini-delegate`, `qwen-delegate`, `copilot-delegate`), or a Claude subagent if none is enabled or its gate blocks |
| Independent second opinion or review of Claude's own work | An external worker |
| Several independent tasks at once | Spread them across workers; never two writers on the same files |
| An external worker failed or returned a big miss | Claude subagent, one model tier above what the task would normally get |

## Choose the Claude model

Pass the Agent tool's `model` parameter. Start at the lowest tier that fits; go up one tier after a failure, not before.

| Model | `model` | Give it |
| --- | --- | --- |
| Haiku | `haiku` | Boilerplate, docs, version bumps, changelog, formatting, renames, log parsing, test scaffolding, single-file mechanical edits, simple lookups |
| Sonnet | `sonnet` | Medium features with a clear spec, multi-file bug fixes, localized refactors, test suites, code review of a small diff, focused research |
| Opus | `opus` | Large features, cross-module refactors, architecture and design, subtle bugs, review of a large or risky diff |
| Fable | `fable` | The hardest work only: cross-repo architecture, root-cause debugging nobody has cracked, novel algorithms, high-ambiguity planning, any task Opus already failed |

If the session cannot use a model (the Agent call rejects it), use the next tier down and say so.

## Prompt template

A fresh subagent has none of this conversation. Include: goal, files in scope and out of scope, conventions (point at an example file), done criteria with a verify command, and "Do not commit. Report changed files and anything unverified."

## After the subagent returns (mandatory)

1. Read `git diff` / `git status`.
2. Re-run the verify command yourself.
3. Fix small issues directly; re-delegate one tier up or take over for big misses.
4. Tell the user which worker and model did the task and what you verified.
