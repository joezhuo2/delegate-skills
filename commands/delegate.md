---
description: Enable, disable or show status of Codex/Kiro delegation (usage: /delegate disable codex | enable kiro | disable all | status)
argument-hint: <enable|disable|status> [codex|kiro|all]
---

Manage `delegate-skills`. Arguments: $ARGUMENTS

State file: `$CLAUDE_CONFIG_DIR/delegate-skills.json` (default `~/.claude/delegate-skills.json`), shape `{"disabled": ["codex", "kiro"]}`. Valid parts: `codex`, `kiro`, `all` (both).

- `disable <part>`: add the part(s) to `disabled`, creating the file if missing.
- `enable <part>`: remove the part(s) from `disabled`.
- `status`: print each part as enabled or disabled.

Read the file (treat missing as `{"disabled": []}`), apply the change, write it back as JSON, then print the resulting status. Do nothing else. While a part is disabled its gate blocks and you must not delegate to it.
