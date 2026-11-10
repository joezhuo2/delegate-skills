# Changelog

## 0.1.3

- Delegation levels: `/delegate low|medium|ultra` (and `delegate-skills low|medium|ultra`). low delegates only on request, medium when appropriate (default), ultra prefers workers over Claude subagents and Claude itself.
- SessionStart hook tells each session the saved level (plugin hook; npm install adds it to settings.json and uninstall removes it).
- README restructured; CI creates the GitHub release when checks pass on a version tag.

## 0.1.2

- codex-run prefers the newest Codex app codex.exe so its sandbox host (codex-code-mode-host.exe) is found; falls back to ~/.codex/.sandbox-bin.

## 0.1.1

- Fix codex gate exit code: runner no longer exits 3 on success.
- codex-run prints the gate exit code on failure.
