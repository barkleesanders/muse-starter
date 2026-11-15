#!/usr/bin/env bash
# Sandbox test for install.sh: every mode, in a fake HOME, with seeded
# conflicts (existing identity file, existing tracker marker, existing
# config). Asserts placements, the held-back gate, the discovery test,
# and the no-overwrite rule. Run before publishing any installer change:
#   bash scripts/test-install.sh
set -euo pipefail
SRC="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
fail() { echo "test-install FAIL: $1" >&2; exit 1; }

run_install() { # $1 = label, rest = args
  local label="$1"; shift
  HOME="$TMP/$label" MUSE_WORKSPACE="$TMP/$label/workspace" bash "$SRC/install.sh" "$@"
}

# Seed an "existing system": identity file, foundation-style config,
# beads tracker marker — the installer must report and respect all three.
seed() {
  mkdir -p "$TMP/$1/workspace"
  echo "MY EXISTING SOUL" > "$TMP/$1/SOUL.md"
  echo "MY EXISTING CONFIG" > "$TMP/$1/workspace/MUSE.md"
  mkdir -p "$TMP/$1/workspace/.beads"
}

echo "--- mode: discoverable (default) ---"
seed a
OUT="$(run_install a)"
echo "$OUT" | grep -q "kept existing .*SOUL.md\|~/SOUL.md exists" || fail "default: existing SOUL.md not reported kept"
grep -q "MY EXISTING SOUL" "$TMP/a/SOUL.md" || fail "default: SOUL.md overwritten"
grep -q "MY EXISTING CONFIG" "$TMP/a/workspace/MUSE.md" || fail "default: MUSE.md overwritten"
echo "$OUT" | grep -q "tracker: beads" || fail "default: preflight missed existing beads tracker"
echo "$OUT" | grep -q "discovery test:" || fail "default: no discovery test output"
[ -f "$TMP/a/workspace/custom-skills/decompile/SKILL.md" ] || \
  [ -f "$TMP/a/workspace/skills/decompile/SKILL.md" ] || fail "default: decompile missing entirely"
# goal is a tracker skill: files-only by default, never discoverable
[ -f "$TMP/a/workspace/skills/goal/SKILL.md" ] || fail "default: goal should be filed as library"
[ ! -e "$TMP/a/workspace/custom-skills/goal" ] || fail "default: goal must NOT be discoverable without opt-in"
echo "$OUT" | grep -q "tools installed:.*none" || fail "default: summary must state no tools installed"
echo "$OUT" | grep -q "activated state:.*none" || fail "default: summary must state no state activated"

echo "--- mode: files-only ---"
seed b
OUT="$(run_install b --mode files-only)"
[ -f "$TMP/b/workspace/skills/decompile/SKILL.md" ] || fail "files-only: decompile not in library"
[ ! -e "$TMP/b/workspace/custom-skills" ] || fail "files-only: custom-skills must not be created"

echo "--- mode: activate (one gated skill) ---"
seed c
OUT="$(run_install c --activate goal)"
[ -f "$TMP/c/workspace/custom-skills/goal/SKILL.md" ] || fail "activate: goal not discoverable after --activate goal"
[ ! -e "$TMP/c/workspace/custom-skills/taskmaster" ] || fail "activate: taskmaster must stay held back"

echo "--- mode: activate (all) ---"
seed d
OUT="$(run_install d --mode activate)"
[ -f "$TMP/d/workspace/custom-skills/taskmaster/SKILL.md" ] || fail "activate-all: taskmaster not discoverable"
echo "$OUT" | grep -q "Activating opt-in skills" || fail "activate-all: opt-in list not printed first"

echo "--- preflight only ---"
seed e
OUT="$(run_install e --preflight)"
[ ! -e "$TMP/e/workspace/custom-skills" ] && [ ! -e "$TMP/e/workspace/skills" ] || fail "preflight: files were copied"

echo "test-install: ALL PASS"
