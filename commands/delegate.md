---
description: Set delegation level or enable/disable Codex/Kiro/Gemini/Qwen/Copilot/Claude delegation (usage: /delegate low | medium | ultra | disable codex | enable kiro | disable all | status)
argument-hint: <low|medium|ultra|enable|disable|status> [codex|kiro|gemini|qwen|copilot|claude|all]
---

Manage `delegate-skills`. Arguments: $ARGUMENTS

State file: `$CLAUDE_CONFIG_DIR/delegate-skills.json` (default `~/.claude/delegate-skills.json`), shape `{"level": "medium", "disabled": ["codex", "kiro"]}`. Valid parts: `codex`, `kiro`, `gemini`, `qwen`, `copilot`, `claude` (native Claude subagents with model routing), `all` (every part).

- `low` / `medium` / `ultra`: set `level`.
- `disable <part>`: add the part(s) to `disabled`, creating the file if missing.
- `enable <part>`: remove the part(s) from `disabled`.
- `status`: print the level (missing means `medium`) and each part as enabled or disabled.

Read the file (treat missing as `{"level": "medium", "disabled": []}`), apply the change, write it back as JSON, then print the resulting status. Do nothing else.

Levels (a SessionStart hook injects the saved level into new sessions; after a change, follow the new level for the rest of this session too):

- `low`: delegate only when the user explicitly asks.
- `medium` (default): delegate when a task fits the skill's "when to delegate" rules.
- `ultra`: prefer delegating over doing the work yourself; keep only orchestration, review, and work no worker can do.

While `claude` is enabled you are the orchestrator: per task, choose between an external worker and a Claude subagent on the model that fits (see `claude-delegate`). With `claude` disabled, `ultra` also prefers external workers over Claude subagents.

While a part is disabled its gate blocks and you must not delegate to it.
