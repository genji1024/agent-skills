# agent-skills

Reusable Agent Skills (SKILL.md format, `anthropics/skills` convention).

## Install

```sh
git clone https://github.com/genji1024/agent-skills.git
cd agent-skills && ./install.sh
```

This symlinks `~/.agents/skills` to this repo's `skills/` directory (replacing
it if it already exists). Re-run `install.sh` any time after a `git pull` to
keep the symlink current — nothing else to do, the symlink already tracks
new/removed skills automatically.

## Contents

**Cross-cutting** (apply regardless of project — see
[`skills/writing-skills`](./skills/writing-skills/SKILL.md) for the rule on
what counts as cross-cutting vs. project-specific):

- [`writing-skills`](./skills/writing-skills/SKILL.md) — how to write/place a skill
- [`general`](./skills/general/SKILL.md) — baseline rules for every task
- [`environment`](./skills/environment/SKILL.md) — facts about the container
  this runs in (from the `g-ohara/dotfiles` opencode setup)
- [`session-lessons`](./skills/session-lessons/SKILL.md) — extract lessons
  from a session and turn them into skill updates
- [`commit-message`](./skills/commit-message/SKILL.md) — commit message
  generation, matching a repo's existing convention

**Owner/project-specific** (nested — only OpenCode's recursive skill
discovery sees these; see `writing-skills` for why):

- [`genji1024/`](./skills/genji1024/) — skills for genji1024-owned repos
  (`autonomous-engineer` base pattern plus its `github-autonomous-engineer`/
  `forgejo-autonomous-engineer` instances, shared `build-and-verify`/
  `pr-workflow`/`merge-conflict-resolution`, and `private-note/`'s own
  app-specific skills)
- [`cpp-coursework/`](./skills/cpp-coursework/) — skills for a specific
  C++/GitLab course project (`doc-writing`, `mr-review`)

**Read [`writing-skills`](./skills/writing-skills/SKILL.md) before adding anything here.**
