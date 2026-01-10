#!/bin/sh
set -eu

src=$(readlink -f "$1")
dst="$2"

mkdir -p "$dst"

# 1. Create directory structure (relative paths)
find "$src" -type d -printf '%P\n' | while IFS= read -r rel; do
  [ -z "$rel" ] && continue
  mkdir -p "$dst/$rel"
done

# 2. Recreate symlinks exactly (relative link text preserved)
find "$src" -type l -printf '%P\n' | while IFS= read -r rel; do
  target=$(readlink "$src/$rel")
  ln -s "$target" "$dst/$rel"
done

# 3. Replace regular files with symlinks to original files
find "$src" -type f -printf '%P\n' | while IFS= read -r rel; do
  ln -s "$src/$rel" "$dst/$rel"
done
