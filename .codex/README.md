# .codex/ overview

This directory makes the repo's Claude Code configuration available to Codex by symlinking to the canonical Claude files. Claude remains the single source of truth; edits should be made in `.claude/` and Codex reads them through the symlinks below.

## Root instructions
- `AGENTS.md` (repo root) holds the project rules; `CLAUDE.md` is a symlink to it.

## What's symlinked here
- `agents/*.md` -> `../../.claude/agents/` — agent definitions
  (`git-review`, `gui-validate`, `ha-engineer`, `k8s-engineer`, `tf-engineer`)
- `commands/k8s.md` -> `../../.claude/commands/` — `/k8s` slash command
- `agent-memory/<agent>/*.md` -> `../../../.claude/agent-memory/<agent>/` — per-agent memory/notes

## Not mapped (no direct Codex equivalent)
- `.claude/settings.local.json` — Codex uses `config.toml` instead
- `.claudeignore` — ignore handling is done via `.gitignore`

## Maintenance
To re-create or refresh the symlinks after adding new files under `.claude/`:
```sh
# agents
for f in .claude/agents/*.md; do ln -sf "../../.claude/agents/$(basename "$f")" ".codex/agents/$(basename "$f")"; done
# commands
ln -sf ../../.claude/commands/k8s.md .codex/commands/k8s.md
# memory
(cd .claude/agent-memory && for f in $(find . -type f); do r="${f#./}"; mkdir -p "../../.codex/agent-memory/$(dirname "$r")"; ln -sf "../../../.claude/agent-memory/$r" "../../.codex/agent-memory/$r"; done)
```
Verify nothing is broken with: `find .codex -type l ! -exec test -e {} \; -print` (should print nothing).
