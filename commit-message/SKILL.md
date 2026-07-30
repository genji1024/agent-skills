---
name: commit-message
description: Rule to reference commit history and match format when generating commit messages
---

# SKILL: Commit Message Generation

## 0. CRITICAL DIRECTIVES
- *Immediate Execution:* When invoked via `/commit-message`, DO NOT acknowledge, summarize, display rules, or ask what to do. Begin execution immediately at step 1.
- *Output Format:* Always output commit messages as Plain Text. DO NOT wrap the final commit message in markdown code blocks.

---

## 1. FORMATTING CONSTRAINTS (Apply to ALL commit messages)
Regardless of how this skill is triggered, the following formatting rules strictly apply:
- *Format Matching:* Must match the project's historical convention (either Gitmoji `<emoji> <description>` OR Conventional Commits `<type>(scope): <description>`).
- *Line Length:* Every line MUST be 72 characters or less. Wrap long bullet points to the next line.
- *Structure:*
    - *Headline (First Line):* Max ~50 characters. Semantic description of what changed and why.
    - *Body:* Separated by a blank line. Formatted as bullet points (`-`). Must use capped top-level bullets and thorough sub-bullets.
- *Content (Semantic over Literal):* Describe the "why" and "what" in plain English. DO NOT just quote code changes. Avoid referencing specific code values, command flags, or identifiers unless strictly necessary. Use backticks sparingly.
- *Syntax:* Use Markdown style, NOT HTML.

---

## 2. WORKFLOW A: Slash Command (`/commit-message`)

*[TRIGGER]* User inputs `/commit-message`.

*[STEPS]*
1.  *Verify Staged Changes:*
    - Run: `git diff --cached --no-color`
    - *IF* no output: Return error `No staged changes.` and halt.
2.  *Read Commit History:*
    - Run: `git log --format="%B" -10`
    - *ACTION:* Analyze output to determine if the project uses Gitmoji or Conventional Commits.
3.  *Inspect Changes:*
    - *ACTION:* Analyze `git diff --cached` output. Identify touched files/directories and group logical changes by scope.
4.  *Draft Message Internally:*
    - Determine the most impactful change for the headline.
    - Group the rest into body bullets.
    - Apply rules from `1. FORMATTING CONSTRAINTS`.
5.  *Confirm Headline:*
    - *ACTION:* Use the `question` tool.
    - *PROMPT:* `"Does the first line look like this: <first line>?"`
6.  *Preview Full Message:*
    - *ACTION:* Generate the full message (Plain text, NO code blocks).
7.  *Ask for Approval:*
    - *ACTION:* Use the `question` tool.
    - *PROMPT:* `"Accept?"` (Include the full commit message in the question text for review).
8.  *Handle User Response:*
    - *IF ACCEPTED:* Output the exact message to `stdout` as plain text (no prompts, no code blocks) for easy copying.
    - *IF REJECTED:* Use the `question` tool to ask `"What would you like to change?"`. Provide options. Receive feedback, then restart from *Step 4*.

---

## 3. WORKFLOW B: General Execution

*[TRIGGER]* Agent generates a commit message as part of a broader task (NOT via slash command).

*[STEPS]*
1.  *Verify Staged Changes:* Use `git diff --cached` to ensure only staged changes are included.
2.  *Read Commit History:* Always run `git log --format="%B"` (Must be multi-line command to preserve full bodies) to determine style.
3.  *Generate Message:* Apply all rules from `1. FORMATTING CONSTRAINTS`.
4.  *Confirm:* Always use the `question` tool to ask for the user's acceptance before proceeding with the commit.
