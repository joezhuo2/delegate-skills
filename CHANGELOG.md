# Changelog

## 0.1.5

- New worker: `claude-delegate`. The main Claude session acts as orchestrator and chooses per task between an external worker and a native Claude subagent, run on the model that fits: Haiku (boilerplate, docs), Sonnet (medium features), Opus (large features, refactors, subtle bugs), Fable (hardest work only).
- `delegate-skills enable|disable` and `/delegate` accept `claude`; the level hook adds the orchestrator rule while `claude` is enabled.
- `ultra` no longer ranks external workers above Claude subagents unless `claude` is disabled.

## 0.1.4

- New workers: `gemini-delegate` (Gemini CLI), `qwen-delegate` (Qwen Code) and `copilot-delegate` (GitHub Copilot CLI). Each runs headless, read-only by default, `-Write` to allow edits; uses the CLI's default model unless `-Model <id>` is passed (#1).
- `delegate-skills enable|disable` and `/delegate` accept `gemini`, `qwen`, `copilot`; the level hook lists only enabled workers.
- README documents the new workers.

## 0.1.3

- Delegation levels: `/delegate low|medium|ultra` (and `delegate-skills low|medium|ultra`). low delegates only on request, medium when appropriate (default), ultra prefers workers over Claude subagents and Claude itself.
- SessionStart hook tells each session the saved level (plugin hook; npm install adds it to settings.json and uninstall removes it).
- README restructured; CI creates the GitHub release when checks pass on a version tag.

## 0.1.2

- codex-run prefers the newest Codex app codex.exe so its sandbox host (codex-code-mode-host.exe) is found; falls back to ~/.codex/.sandbox-bin.

## 0.1.1

- Fix codex gate exit code: runner no longer exits 3 on success.
- codex-run prints the gate exit code on failure.
