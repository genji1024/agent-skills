# agent-skills

Reusable Agent Skills (SKILL.md format, `anthropics/skills` convention).

## Install

```sh
git clone https://github.com/genji1024/agent-skills.git
cd agent-skills && ./install.sh
```

This symlinks `~/.agents/skills` to this repo's `skills/` directory (for
OpenCode, which reads the tree recursively), and links every skill into
`~/.claude/skills/<name>` (for Claude Code, which reads only one level there
and does not load `~/.agents/skills`). Re-run `install.sh` after a
`git pull` that adds, renames or removes skills; it also drops links to
skills that no longer exist.

## Contents

**Cross-cutting** (apply regardless of project — see
[`skills/writing-skills`](./skills/writing-skills/SKILL.md) for the rule on
what counts as cross-cutting vs. project-specific):

- [`writing-skills`](./skills/writing-skills/SKILL.md) — how to write/place a skill
- [`general`](./skills/general/SKILL.md) — baseline rules for every task
- [`environment`](./skills/environment/SKILL.md) — facts about the containers
  these run in (the `g-ohara/dotfiles` opencode setup and the
  `genji1024/containerized-agents` claude-code container)
- [`session-lessons`](./skills/session-lessons/SKILL.md) — extract lessons
  from a session and turn them into skill updates
- [`commit-message`](./skills/commit-message/SKILL.md) — commit message
  generation, matching a repo's existing convention

**Owner/project-specific** (nested for organisation; flattened by the links
above so Claude Code sees them too — see `writing-skills`):

- [`genji1024/`](./skills/genji1024/) — skills for genji1024-owned repos
  (`autonomous-engineer` base pattern plus its `github-autonomous-engineer`/
  `forgejo-autonomous-engineer` instances, shared `build-and-verify`/
  `pr-workflow`/`merge-conflict-resolution`, `private-note/`'s own
  app-specific skills, and `koto`)
- [`cpp-coursework/`](./skills/cpp-coursework/) — skills for a specific
  C++/GitLab course project (`doc-writing`, `mr-review`)

**Read [`writing-skills`](./skills/writing-skills/SKILL.md) before adding anything here.**
