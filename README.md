<h1 align="center">delegate-skills</h1>

<p align="center">
  <a href="https://www.npmjs.com/package/delegate-skills"><img src="https://img.shields.io/npm/v/delegate-skills?logo=npm&color=orange" alt="npm"></a>
  <a href="https://www.npmjs.com/package/delegate-skills"><img src="https://img.shields.io/npm/dt/delegate-skills?logo=npm&color=blue" alt="downloads"></a>
  <a href="https://github.com/joezhuo2/delegate-skills/releases/latest"><img src="https://img.shields.io/github/v/release/joezhuo2/delegate-skills?logo=github" alt="release"></a>
  <a href="https://github.com/joezhuo2/delegate-skills/actions/workflows/ci.yml"><img src="https://img.shields.io/github/actions/workflow/status/joezhuo2/delegate-skills/ci.yml?branch=claude%2Fchanges&label=CI&logo=githubactions&logoColor=white" alt="CI"></a>
  <img src="https://img.shields.io/badge/platform-Windows-lightgrey" alt="platform: Windows">
  <a href="LICENSE"><img src="https://img.shields.io/github/license/joezhuo2/delegate-skills?color=green" alt="license"></a>
</p>

<p align="center">
  <a href="#install">Install</a> •
  <a href="#features">Features</a> •
  <a href="#commands">Commands</a> •
  <a href="#files">Files</a> •
  <a href="#development">Development</a> •
  <a href="#license">License</a>
</p>

> delegate-skills is a set of Claude Code skills that let Claude hand
> self-contained tasks to other AI coding agents (Codex, Kiro, Gemini CLI,
> Qwen Code and GitHub Copilot CLI),
> then review what they did. A delegation level decides how eagerly Claude
> hands work off, from only when you ask to almost everything.

## Install

Requires Windows, Node 18+ and Claude Code.

From npm. Copies the skills, the `/delegate` command and a SessionStart hook
into `~/.claude`:

```bash
npm i -g delegate-skills
delegate-skills install
```

Or one-off, without a global install:

```bash
npx delegate-skills install
```

Or as a Claude Code plugin:

```
/plugin marketplace add joezhuo2/delegate-skills
/plugin install delegate-skills@delegate-skills
```

Use one method, not both: with both, each session gets the level message twice.

### Workers

- **Codex:** the Codex desktop app, signed in on a ChatGPT plus plan. The
  runner uses the newest `codex.exe` under `%LOCALAPPDATA%\OpenAI\Codex\bin`,
  falling back to `~/.codex/.sandbox-bin/codex.exe`.
- **Kiro:** install the Windows MSI listed in
  `https://prod.download.cli.kiro.dev/stable/latest/manifest.json` (check the
  sha256), then run `kiro-cli login`.
- **Gemini:** `npm i -g @google/gemini-cli`, then run `gemini` once and sign
  in (Google login or `GEMINI_API_KEY`).
- **Qwen Code:** `npm i -g @qwen-code/qwen-code`, then run `qwen` once and
  sign in or pick an auth type.
- **Copilot:** `npm i -g @github/copilot`, then run `copilot` and `/login`
  (needs a Copilot plan).

You only need the worker(s) you plan to use; disable the others.

### Updates

```bash
npm i -g delegate-skills@latest
delegate-skills install
```

Plugin installs update with `/plugin update delegate-skills`. Restart Claude
Code after updating.

### Uninstall

```bash
delegate-skills uninstall
npm rm -g delegate-skills
```

`uninstall` removes the skills, the command, the hook script and its
`settings.json` entry. Your level and disabled parts stay in
`~/.claude/delegate-skills.json`.

## Features

### Skills

| Skill | Worker | Gate |
| --- | --- | --- |
| `codex-delegate` | Codex CLI (`gpt-6.1-sol` or `gpt-6-astra`, medium effort) | ChatGPT **plus** plan, 5h and weekly usage under 95% |
| `kiro-delegate` | Kiro CLI (Claude Opus / Sonnet / Haiku, newest available) | CLI installed and logged in |
| `gemini-delegate` | Gemini CLI (its default model) | CLI installed |
| `qwen-delegate` | Qwen Code (its default model) | CLI installed |
| `copilot-delegate` | GitHub Copilot CLI (its default model) | CLI installed |

For Gemini, Qwen and Copilot the CLI's default model is used unless Claude
passes `-Model <id>`. Claude picks the model per task, writes a self-contained prompt, runs the
worker headless, then reads the diff and re-runs the verify command itself.
Workers never commit; Claude owns commits.

### Delegation levels

| Level | Claude delegates |
| --- | --- |
| `low` | Only when you explicitly ask it to |
| `medium` (default) | When a task fits the skill's rules: bounded, few files, verifiable |
| `ultra` | Instead of Claude subagents and instead of doing the work itself, whenever a worker can do it |

On `ultra`, Claude keeps only orchestration, review of worker output and work
no worker can do, and falls back to subagents or itself only when every gate
blocks or the worker fails.

A SessionStart hook reads the saved level and tells each new session. A level
set with `/delegate` also applies to the current session.

### Gates

Each worker runs behind a gate script that blocks before the worker starts:

- **Codex:** blocks unless the login is on the plus plan and neither the 5h nor
  the weekly window is at 95% or more.
- **Kiro:** blocks if `kiro-cli` is missing or not logged in.
- **Gemini, Qwen, Copilot:** block if the CLI is missing. A missing sign-in
  or exhausted quota shows up after the run as `<CLI>_AUTH` or `<CLI>_LIMIT`.
- **All:** block while that part is disabled.

On a block, Claude does the task itself or with a normal subagent.

### Read-only by default

Workers run read-only unless Claude passes `-Write`. Codex then gets a
`workspace-write` sandbox limited to the project folder; Kiro gets
`--trust-all-tools`, Gemini and Qwen get `--approval-mode yolo`, and Copilot
gets `--allow-all`, so those are only used on a git repo Claude can diff.
Read-only runs use Kiro `--trust-tools=fs_read`, Gemini and Qwen
`--approval-mode plan`, and Copilot with write and shell tools denied.

## Commands

Inside Claude Code (plugin and npm installs):

| Command | Does |
| --- | --- |
| `/delegate low` | Delegate only on request |
| `/delegate medium` | Delegate when appropriate (default) |
| `/delegate ultra` | Delegate over subagents and Claude itself |
| `/delegate disable codex` | Stop Codex delegation (`kiro`, `gemini`, `qwen`, `copilot`, `all` also work) |
| `/delegate enable kiro` | Turn a part back on |
| `/delegate status` | Show level and parts |

From a terminal (npm installs):

```bash
delegate-skills ultra            # or low, medium
delegate-skills disable codex    # or kiro, gemini, qwen, copilot, all
delegate-skills enable codex
delegate-skills status
```

## Files

| What | Where |
| --- | --- |
| Level and disabled parts | `~/.claude/delegate-skills.json` |
| Skills | `~/.claude/skills/<part>-delegate/` (codex, kiro, gemini, qwen, copilot) |
| `/delegate` command | `~/.claude/commands/delegate.md` |
| SessionStart hook script | `~/.claude/delegate-skills/level.js` |
| Hook entry | `hooks.SessionStart` in `~/.claude/settings.json` |

Paths follow `CLAUDE_CONFIG_DIR` when it is set. Plugin installs keep the
skills, command and hook inside the plugin instead.

## Development

### Layout

```
bin/cli.js                 npm CLI: install, uninstall, level, enable/disable, status
hooks/level.js             SessionStart hook: prints the level for Claude
hooks/hooks.json           plugin hook registration
commands/delegate.md       /delegate slash command
skills/codex-delegate/     SKILL.md, codex-gate.ps1, codex-run.ps1
skills/kiro-delegate/      SKILL.md, kiro-gate.ps1, kiro-run.ps1
skills/gemini-delegate/    SKILL.md, gemini-gate.ps1, gemini-run.ps1
skills/qwen-delegate/      SKILL.md, qwen-gate.ps1, qwen-run.ps1
skills/copilot-delegate/   SKILL.md, copilot-gate.ps1, copilot-run.ps1
.claude-plugin/            plugin and marketplace manifests
```

### Tests

CI (`.github/workflows/ci.yml`, Windows) parses every PowerShell script,
smoke-tests the CLI against a temporary `CLAUDE_CONFIG_DIR`, checks that the
versions in `package.json`, `plugin.json` and the tag match and that
`CHANGELOG.md` has an entry, and runs `npm pack --dry-run`. Run the same smoke
test locally:

```bash
CLAUDE_CONFIG_DIR=$(mktemp -d) node bin/cli.js install
```

### Releasing

Bump the version in `package.json`, `.claude-plugin/plugin.json` and
`.claude-plugin/marketplace.json`, add a `CHANGELOG.md` entry, commit, then
push a tag:

```bash
git tag v0.1.4
git push origin v0.1.4
```

When CI passes on the tag, it creates (or updates) the GitHub release with the
changelog entry and the npm tarball attached. Publish to npm by hand:

```bash
npm publish
```

## License

[MIT](LICENSE)
