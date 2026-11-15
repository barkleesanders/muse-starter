#!/usr/bin/env bash
# Publish gate — run before EVERY push to this repo, especially a
# "refresh" rebuilt from another source tree.
#
# Founding incident (2026-11-07 refresh, found 2026-11-14): the refresh
# was rebuilt from a stale local source copy and pushed over a live repo
# that already contained a discovery fix. The push silently reverted
# install.sh to the broken target and dropped the PORTING discovery
# section. Nothing failed; the pack just stopped working for new users.
#
# This gate makes that class of mistake fail loudly:
#   1. Refuses if local main is behind origin/main (you are about to
#      publish from a stale base — fetch and re-apply instead).
#   2. Lists every guarded file whose content would change vs
#      origin/main, so a revert of a guarded file is a deliberate,
#      visible act, never a side effect of a bulk copy.
#   3. Runs the installer contract check and the sandbox install test.
set -euo pipefail
cd "$(dirname "$0")/.."

GUARDED="install.sh MUSE.md PORTING.md BEADS.md SETUP.md MANIFEST.json scripts/check-installer.sh scripts/test-install.sh scripts/generate-manifest.py scripts/generate-skill-yaml.py"

git fetch origin --quiet
BASE="$(git merge-base HEAD origin/main)"
if [ "$BASE" = "$(git rev-parse HEAD)" ] && [ "$(git rev-parse HEAD)" != "$(git rev-parse origin/main)" ]; then
  echo "publish-check FAIL: local main is BEHIND origin/main (stale base)." >&2
  echo "  A refresh must start FROM the live repo: fetch, fast-forward, then re-apply your changes on top." >&2
  exit 1
fi
if [ "$BASE" != "$(git rev-parse HEAD)" ] && [ "$BASE" != "$(git rev-parse origin/main)" ]; then
  echo "publish-check FAIL: local main has DIVERGED from origin/main." >&2
  echo "  Reconcile against the live repo before publishing; never overwrite it from a side tree." >&2
  exit 1
fi
[ -f scripts/check-installer.sh ] || { echo "publish-check FAIL: scripts/check-installer.sh missing from this tree" >&2; exit 1; }

CHANGED=""
for f in $GUARDED; do
  if ! git diff --quiet origin/main -- "$f" 2>/dev/null || \
     [ -n "$(git status --porcelain -- "$f")" ]; then
    CHANGED="$CHANGED $f"
  fi
done
if [ -n "$CHANGED" ]; then
  echo "publish-check: guarded files changing in this publish:$CHANGED"
  echo "  Confirm each change is intentional and not a stale-source revert:"
  git diff origin/main --stat -- $CHANGED | sed 's/^/    /'
fi

bash scripts/check-installer.sh
bash scripts/test-install.sh >/dev/null && echo "publish-check: sandbox install test PASS"
echo "publish-check: OK — safe to push"
