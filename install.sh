#!/bin/bash -e

REPO="$(cd "$(dirname "$0")" && pwd)"

# The cross-tool location (opencode, Cursor): one link for the whole tree.
AGENTS="$HOME/.agents/skills"
echo "Linking $REPO/skills -> $AGENTS"
mkdir -p "$(dirname "$AGENTS")"
ln -snfv "$REPO/skills" "$AGENTS"

# Claude Code reads only ~/.claude/skills and <project>/.claude/skills, finds
# skills one level down (*/SKILL.md), and shares that directory with skills the
# app manages itself — so link each skill separately, by its own name.
CLAUDE="$HOME/.claude/skills"
echo "Linking each skill -> $CLAUDE"
mkdir -p "$CLAUDE"
# Drop links this script made for skills that have since been renamed or removed.
for link in "$CLAUDE"/*; do
  [ -L "$link" ] || continue
  case "$(readlink "$link")" in "$REPO"/skills/*) [ -e "$link" ] || rm -v "$link" ;; esac
done
find "$REPO/skills" -name SKILL.md -exec dirname {} \; | while read -r skill; do
  ln -snfv "$skill" "$CLAUDE/$(basename "$skill")"
done

echo "Success"
