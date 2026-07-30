---
name: writing-skills
description: How to add, edit, or restructure a skill file in this ~/.agents/skills/ directory (frontmatter rules, where a new skill should live, when to extend vs create). Load this before creating a new skill or editing an existing one's structure.
---

# Writing Skills

## Frontmatter

- `name`: lowercase letters, numbers, hyphens only. ≤64 chars. Never "claude" or "anthropic".
- `description`: ≤1024 chars, non-empty, third person ("Processes X", not "I can help with X"). State both **what it does** and **when to use it**, with specific key terms — not "helps with documents" or "does stuff with files".

## Where does this skill go?

This directory is shared across unrelated projects and read by two different
tools with different discovery rules:

- **Claude Code only discovers direct children of `skills/`**
  (`skills/<name>/SKILL.md`). Anything nested one level deeper never appears
  in its available-skills list — confirmed empirically, not documented
  behavior to assume elsewhere.
- **OpenCode reads the whole tree recursively.**

Decision rule:

1. **Cross-cutting** (applies no matter which project/repo you're working
   in — e.g. `general`, `environment`, `commit-message`, `writing-skills`
   itself) → top-level (`skills/<name>/`). This makes it visible to both tools.
2. **Specific to one repo** (hardcodes a DB, a user model, a URL, a build
   convention that only that repo uses) → nest under `skills/<owner>/<project>/`,
   e.g. `skills/genji1024/private-note/`. Only OpenCode will see it — that's
   fine, Claude Code sessions on unrelated repos don't need it anyway.
3. **Shared by several repos under one owner, but not universal** (e.g. a
   PR/CI convention two of that owner's repos happen to both use) → sits
   directly under `skills/<owner>/`, a sibling of the project folders, not
   duplicated into each one.

Before creating a new skill, check whether an existing one already covers
it — grep sibling skills for the topic first. If it's a small variant of an
existing rule, extend that file instead of creating a new one. Don't restate
the same convention in two places under the excuse of "it's a different
repo" if the underlying rule is actually identical (rule 3 above exists
specifically to avoid that).

## Keep it concise

Claude/OpenCode already knows generic facts. Only write what it couldn't
already know: project-specific values, discovered constraints, non-obvious
gotchas. Don't explain what a PDF is before showing how to parse one.

- Keep SKILL.md under 500 lines. Split overflow into reference files linked
  **one level deep only** from SKILL.md — don't nest references inside
  references, or the agent may only skim them with `head`.
- Reference files over ~100 lines get a table of contents at the top.
- Pick one term per concept and use it everywhere in the file (don't mix
  "API endpoint" / "URL" / "route" for the same thing).
- Don't write time-sensitive statements ("before August 2025, use X"). If a
  pattern is genuinely deprecated, put the old one under a collapsed
  `<details>` "old patterns" section instead of deleting context outright.

## Anti-patterns (found in this repo before this cleanup — don't reintroduce them)

- **Dead cross-references.** A skill linked to `../commit-control/SKILL.md`
  and `project-context`, neither of which existed. Check that every
  `[link](../path/SKILL.md)` you write actually resolves before moving on.
- **Copy-pasted checklists.** The same 4-step CI check
  (`lint`/`format:check`/`typecheck`/`build`) was duplicated near-verbatim
  across three separate skill files. If two skills need the same steps,
  one should link to the other, not repeat it.
- **Stale naming.** A repo was renamed and skill bodies kept using the old
  name long after — confusing, and eventually wrong (e.g. hardcoded old
  project name inside a still-active skill). Update in-body mentions when
  you learn a name changed, not just the folder.
- **Vague, unscoped descriptions.** `"description: Helps with documents"`
  tells nothing about when to load it. Every project-specific skill's
  description should name its repo.

## Before considering an edit done

- [ ] `name`/`description` valid per the rules above
- [ ] Description names what it does + when to use it + (if project-specific) which repo
- [ ] Placed per the decision rule above (top-level vs `<owner>/` vs `<owner>/<project>/`)
- [ ] No content duplicated from a sibling skill — link instead
- [ ] Every relative link in the file actually resolves
- [ ] No stale project names or time-sensitive claims

## Cross-Reference

- [`session-lessons`](../session-lessons/SKILL.md) — extracts lessons from a
  session and decides whether to update an existing skill or create a new
  one; follow this file's rules once it's decided a skill needs writing.
