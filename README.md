# delegate-skills

Claude Code skills that let Claude hand light/medium, self-contained tasks to other coding agents, then review the result.

| Skill | Worker | Gate |
|-------|--------|------|
| `codex-delegate` | Codex CLI (`gpt-6.1-sol` or `gpt-6-astra`, medium effort) | ChatGPT **plus** plan and 5h/weekly usage under 95% |
| `kiro-delegate` | Kiro CLI (Claude Opus / Sonnet / Haiku, newest available) | CLI installed and logged in |

Claude chooses the model per task. If a gate blocks, Claude does the work itself or uses a normal subagent.

Windows only for now (PowerShell 5.1+ scripts).

## Install

npm (copies the skills into `~/.claude/skills`):

```bash
npm i -g delegate-skills
delegate-skills uninstall   # to remove
```

Claude Code plugin marketplace:

```
/plugin marketplace add joezhuo2/delegate-skills
/plugin install delegate-skills@delegate-skills
```

## Disable parts

State lives in `~/.claude/delegate-skills.json`; each gate checks it first and blocks while its part is disabled.

```bash
delegate-skills disable codex    # no Codex/OpenAI delegation
delegate-skills disable kiro     # no Kiro delegation
delegate-skills disable all
delegate-skills enable codex
delegate-skills status
```

Inside Claude Code (works for plugin installs too): `/delegate disable codex`, `/delegate enable kiro`, `/delegate status`.

## Requirements

- Codex: the Codex desktop app (ships `~/.codex/.sandbox-bin/codex.exe`), signed in.
- Kiro: install the Windows MSI from `https://prod.download.cli.kiro.dev/stable/latest/manifest.json` (verify the sha256), then run `kiro-cli login`.

## Status

- Codex gate and runner: tested (gate blocks correctly; runner reaches Codex).
- Kiro runner: tested read-only on `haiku`, `sonnet` and `opus` (resolved to the 5.5 models from `--list-models`). `-Write` mode (`--trust-all-tools`) is untested.
