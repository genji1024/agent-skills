---
name: session-lessons
description: When triggered, automatically extract reusable lessons from a session and update existing skills or create new ones for smoother future sessions.
---

# Session Lessons

## Overview

This skill defines how to extract reusable lessons from a coding session and apply them to existing skills or create new ones.
It should be invoked via `/session-lessons` command at the end of a session.

## Workflow

### 1. Extract Session Lessons

Review the session conversation and extract:

- **Explicit user instructions/preferences**: Repeated corrections, forceful rejections, or explicit instructions the user gave during the session
- **Discovered conventions/constraints**: Technical restrictions, project-specific rules, or coding conventions that became apparent during the session
- **Repetitive friction points**: Areas where the agent needed repeated corrections or asked redundant questions
- **Tool/command discoveries**: Efficient ways to use tools, specific command patterns, or useful options
- **Improvement opportunities**: "It would have been faster if..." moments

### 2. Compare with Existing Skills

Check if extracted lessons overlap with existing skills:

- **Full overlap**: The lesson is already covered — skip unless it adds meaningful detail
- **Partial overlap**: Update the existing skill with the new information
- **No overlap**: Create a new skill file
- **Conflicting with existing**: Ask the user for clarification

### 3. Apply Changes

Follow [`writing-skills`](../writing-skills/SKILL.md) for frontmatter rules,
where a new skill file should be placed (top-level vs `<owner>/<project>/`),
and how to avoid duplicating an existing skill's content.

When updating an existing skill: append under a clearly marked subsection
if it supplements rather than replaces; don't duplicate existing rules or
sections.

### 4. Report Results

Output a summary of what was done:
```
Session Lessons:
  Updated: skill-name (summary of changes)
  Created: skill-name (brief description)
```

## Output Format

When recording lessons, use this structure:

```markdown
## Session Lessons: <date>

### Explicit Instructions
- <What the user explicitly instructed or preferred>

### Discovered Conventions
- <Technical constraints, coding conventions, or rules discovered during the session>

### Friction Points
- <Repeated corrections asked by the user>
- <Time-consuming steps that could be automated>

### Skill Changes
- <List of updated/created skill files and the key changes>
```

## Notes

- Record lessons objectively — exclude subjective evaluations or opinions
- Do not record private or sensitive information about the user
- Prioritize generic, reusable lessons over project-specific ones
- If a lesson conflicts with an existing skill, ask the user before overwriting
- Only record specific, actionable lessons — vague observations are not recorded
