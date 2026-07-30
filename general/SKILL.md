---
name: general
description: Baseline rules that apply to every task regardless of domain.
---

# General Principles

## Overview

This skill defines rules that apply to all tasks. It should be loaded for every session.

## Prerequisites

### 1. Check AGENTS.md

Before starting any task, check for the existence of `AGENTS.md` in the project root directory. If it exists, read it and follow its contents. If there is a conflict between `AGENTS.md` and user instructions, ask the user for clarification.

### 2. Read before writing

Understand the file's purpose, conventions, and surrounding context before making changes. Use the Read tool to read the entire file, not just the diff.

### 3. Search before assuming

Use grep/glob to verify existing patterns, conventions, or prior art rather than guessing.

### 4. Confirm before creating files

Never create new source files, plan files, or any files without explicit user permission. Ambiguous confirmations like 「どうぞ」「いいよ」「OK」apply only to the immediately preceding question — do not extend them to imply consent for subsequent operations. Only proceed with file creation after the user gives clear instruction such as 「実装を始める」「ファイルを作成する」.

Modifying plan files (`.opencode/plans/`) — including editing, appending, or restructuring — also requires explicit user permission. Treat plan file changes the same as creating new source files: wait for a clear instruction such as 「計画書を更新する」「方針を修正する」before making changes.

### 5. .gitignore inside .opencode/

When creating files **inside** `.opencode/`, always update `.opencode/.gitignore` (not the project root's `.gitignore`) so that plan/generated files are not tracked.

### 6. Load domain-specific skill for the task type

When the task or request mentions any of the following, load the corresponding additional skill:
- Running shell commands that depend on OS, package manager, init system, or filesystem layout → [`environment`](../environment/SKILL.md)
- GitLab Issue/MR operations, comments, or review on the cpp-coursework project (e.g. "Read Issue #7", "Review MR #N") → [`mr-review`](../cpp-coursework/mr-review/SKILL.md) (uses `gitlab_*` MCP tools served by the `gitlab-mcp` container)
- Documentation creation/modification on the cpp-coursework project → [`doc-writing`](../cpp-coursework/doc-writing/SKILL.md)
- Commit message writing or `/commit-message` (any project) → [`commit-message`](../commit-message/SKILL.md)

These skills provide task-specific workflows (e.g., review guidelines for MRs, formatting styles for Markdown docs, commit formats). Load them automatically when the relevant keywords/commands appear in the user's request, in addition to the always-loaded `general` skill.

## Execution Rules

1. **Minimum necessary change.** Only modify what is required to fulfill the user's request. Do not refactor unrelated code.

2. **Ask when unsure.** If unsure about something, ask or verify — do not guess and commit errors.

3. **Never commit without explicit user approval.**
   - Only commit on explicit user instructions ("commit", "execute", "ok to proceed")
   - Never commit on ambiguous responses ("verify first", "confirm then continue")
   - Never commit automatically from a staged state
   - Never commit without showing the diff first
   - Reconfirm the next action when the user's response is hesitant

4. **Update ignore configuration.** If a task involves creating files that should not be tracked by version control (plan files, generated content, build artifacts, cache files), update the project's ignore configuration (`.gitignore`, `.dockerignore`, or equivalents) as part of the write operation.

## When to Load This Skill

Load this skill at the start of every session. Additionally, reload this skill **before making any change** (creating files, modifying code, updating plans) to ensure all rules are fresh in context — especially after a session has run for a while or when switching between tasks.

## Cross-Reference

When writing a commit message, check [`commit-message`](../commit-message/SKILL.md) for format rules. See [`writing-skills`](../writing-skills/SKILL.md) before adding or restructuring any skill file.
