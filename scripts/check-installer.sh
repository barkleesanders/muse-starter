#!/usr/bin/env bash
# Regression guard for the installer/discovery contract.
#
# Founding incident: the 2026-11-07 refresh overwrote the earlier
# discovery fix and install.sh went back to copying skills into
# ~/workspace/skills/ — a folder Muse skill search does not scan — while
# the README still claimed auto-discovery. The pack "installed" and
# silently did nothing. This check fails loudly if that class returns:
#
#   1. install.sh must target custom-skills for discoverable skills.
#   2. README must not claim ~/workspace/skills/ is auto-discovered.
#   3. MANIFEST.json must cover every skill folder exactly.
#   4. Every skill must ship SKILL.md + skill.yaml (discovery requires both).
#   5. MUSE.md must give the custom-skills path, not the library path,
#      as where discovered skills live.
set -euo pipefail
cd "$(dirname "$0")/.."
fail=0
err() { echo "check-installer FAIL: $1" >&2; fail=1; }

grep -q 'custom-skills' install.sh || err "install.sh does not target custom-skills"
if grep -E 'workspace/skills.*[Aa]uto-discovered' README.md >/dev/null; then
  err "README claims ~/workspace/skills/ is auto-discovered"
fi
grep -q 'custom-skills' MUSE.md || err "MUSE.md does not name the custom-skills discovery path"
[ -f SETUP.md ] || err "SETUP.md missing (beads + tools setup flow)"
grep -q 'bd init' SETUP.md 2>/dev/null || err "SETUP.md does not cover beads install/init"
grep -q 'SETUP.md' README.md || err "README does not link SETUP.md"

python3 - <<'PY' || exit 1
import json, sys
from pathlib import Path
dirs = sorted(p.name for p in Path("skills").iterdir() if p.is_dir())
d = json.load(open("MANIFEST.json"))
names = sorted(d["skills"])
if dirs != names:
    print(f"check-installer FAIL: MANIFEST covers {len(names)} skills, tree has {len(dirs)}; "
          f"missing={sorted(set(dirs)-set(names))} extra={sorted(set(names)-set(dirs))}", file=sys.stderr)
    sys.exit(1)
missing = [n for n in dirs
           if not (Path("skills")/n/"SKILL.md").exists() or not (Path("skills")/n/"skill.yaml").exists()]
if missing:
    print(f"check-installer FAIL: skills missing SKILL.md or skill.yaml: {missing}", file=sys.stderr)
    sys.exit(1)
print(f"check-installer: manifest covers {len(dirs)}/{len(dirs)} skills; all ship SKILL.md + skill.yaml")
PY

if [ "$fail" = "1" ]; then exit 1; fi
echo "check-installer: OK"
