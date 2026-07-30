#!/bin/bash -e

TARGET="$HOME/.agents/skills"

echo "Linking $(pwd)/skills -> $TARGET"

mkdir -p "$(dirname "$TARGET")"
ln -snfv "$(pwd)/skills" "$TARGET"

echo "Success"
