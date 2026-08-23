# .codex/ overview

This directory makes the repo's configuration available to Codex. Two things live here:
native Codex config (custom agents as TOML) and symlinks to canonical Claude files for
shared data. **Claude and Codex each have their own agent formats and are maintained in
parallel — see "Dual-maintenance rule" below.**

## Root instructions
- `AGENTS.md` (repo root) holds the project rules; `CLAUDE.md` is a symlink to it.

## Custom agents (`agents/*.toml`) — native Codex format
Codex does **not** understand Claude's `.md` agent files. It only recognizes custom agents as
standalone TOML files in `.codex/agents/*.toml`, each defining `name`, `description`, and
`developer_instructions`. These are **real files, not symlinks**, because the formats differ:
- `.claude/agents/<agent>.md` — Claude Code format (Markdown + YAML frontmatter)
- `.codex/agents/<agent>.toml` — Codex format (TOML)

Current agents: `git-review`, `gui-validate`, `ha-engineer`, `k8s-engineer`, `tf-engineer`.

## What's symlinked here
- `commands/k8s.md` -> `../../.claude/commands/` — `/k8s` slash command
- `agent-memory/<agent>/*.md` -> `../../../.claude/agent-memory/<agent>/` — per-agent memory/notes

## Not mapped (no direct Codex equivalent)
- `.claude/settings.local.json` — Codex uses `config.toml` instead
- `.claudeignore` — ignore handling is done via `.gitignore`

## Dual-maintenance rule (agents)
When you **add a new agent**, create BOTH:
- `.claude/agents/<agent>.md` (Claude Code)
- `.codex/agents/<agent>.toml` (Codex)

When you **change an agent**, apply the change to BOTH files. They must not drift. The two
formats are different, so they cannot be symlinked — keep them in sync manually.

## Maintenance
To re-create or refresh the symlinks after adding new files under `.claude/`:
```sh
# commands
ln -sf ../../.claude/commands/k8s.md .codex/commands/k8s.md
# memory
(cd .claude/agent-memory && for f in $(find . -type f); do r="${f#./}"; mkdir -p "../../.codex/agent-memory/$(dirname "$r")"; ln -sf "../../../.claude/agent-memory/$r" "../../.codex/agent-memory/$r"; done)
```
Verify nothing is broken with: `find .codex -type l ! -exec test -e {} \; -print` (should print nothing).
