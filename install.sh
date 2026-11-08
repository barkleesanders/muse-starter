#!/usr/bin/env bash
#
# Muse Starter installer.
#
# Copies the curated public files into a Muse environment:
#   skills/    -> ${MUSE_WORKSPACE:-$HOME/workspace}/skills/
#   agents/    -> ${MUSE_WORKSPACE:-$HOME/workspace}/agents/
#   commands/  -> ${MUSE_WORKSPACE:-$HOME/workspace}/commands/
#   MUSE.md    -> ${MUSE_WORKSPACE:-$HOME/workspace}/MUSE.md   (only if absent)
#   templates/ -> $HOME/SOUL.md, USER.md, ...                 (only if absent)
#
# Existing files are never overwritten.
set -euo pipefail

SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WS="${MUSE_WORKSPACE:-$HOME/workspace}"

mkdir -p "$WS/skills" "$WS/agents" "$WS/commands"
rsync -a "$SOURCE_DIR/skills/" "$WS/skills/"
rsync -a "$SOURCE_DIR/agents/" "$WS/agents/"
rsync -a "$SOURCE_DIR/commands/" "$WS/commands/"

if [ ! -e "$WS/MUSE.md" ]; then
  cp "$SOURCE_DIR/MUSE.md" "$WS/MUSE.md"
  echo "installed $WS/MUSE.md"
else
  echo "kept existing $WS/MUSE.md"
fi

for f in SOUL.md USER.md MEMORY.md AGENTS.md TOOLS.md IDENTITY.md; do
  if [ ! -e "$HOME/$f" ]; then
    cp "$SOURCE_DIR/templates/$f" "$HOME/$f"
    echo "installed $HOME/$f"
  else
    echo "kept existing $HOME/$f"
  fi
done

printf 'Muse Starter installed: skills=%s/skills agents=%s/agents commands=%s/commands\n' \
  "$WS" "$WS" "$WS"
