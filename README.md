# agent-skills

Reusable, project-agnostic Agent Skills (SKILL.md format, `anthropics/skills`
convention). These are the cross-cutting skills that don't belong to any one
project — see [`writing-skills`](./writing-skills/SKILL.md) for the rule on
what counts as cross-cutting vs. project-specific, and where project-specific
skills should live instead (not in this repo).

**Read [`writing-skills`](./writing-skills/SKILL.md) before adding anything here.**

## Contents

- [`writing-skills`](./writing-skills/SKILL.md) — how to write/place a skill
- [`general`](./general/SKILL.md) — baseline rules for every task
- [`environment`](./environment/SKILL.md) — facts about the container this
  runs in (from the `g-ohara/dotfiles` opencode setup)
- [`session-lessons`](./session-lessons/SKILL.md) — extract lessons from a
  session and turn them into skill updates
- [`commit-message`](./commit-message/SKILL.md) — commit message generation,
  matching a repo's existing convention
- [`cpp-coursework/`](./cpp-coursework/) — skills for a specific C++/GitLab
  course project (`doc-writing`, `mr-review`); not project-agnostic, but
  scoped by its own description so it doesn't leak into unrelated work
