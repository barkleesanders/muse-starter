# Contributing

Keep additions generic, portable, and free of personal information. Add skills
under `skills/<name>/SKILL.md`, agents under `agents/<name>.md`, and commands
under `commands/<name>.md`. Run the repository privacy and secret gates before
opening a pull request.

## Publishing rule (learned the hard way, 2026-11-14)

A refresh or re-conversion must start **from the live repo** — fetch,
fast-forward, then re-apply changes on top. Never publish a tree rebuilt
from a stale source copy over `origin/main`: that is how the 2026-11-07
refresh silently reverted the skill-discovery fix. Before every push, run:

```bash
bash scripts/publish-check.sh
```

It refuses a stale base, lists every guarded file (installer, manifest,
setup docs) your publish would change, and runs the installer contract
check plus the sandbox install test. If you add or edit a skill, also
regenerate the descriptors and the manifest
(`scripts/generate-skill-yaml.py`, `scripts/generate-manifest.py`) —
the check fails when the manifest and the tree disagree.
