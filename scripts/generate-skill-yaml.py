#!/usr/bin/env python3
"""Generate Muse-native `skill.yaml` descriptors for every skill in this repo.

Why: Muse does NOT read Claude Code frontmatter as a skill's identity.
A Muse custom skill is a folder under `~/workspace/custom-skills/` holding
`SKILL.md` (the instructions) plus a `skill.yaml` descriptor carrying the
skill's `name`, `title`, `description`, `category` and `include_in_prompt`.
Without `skill.yaml`, a skill installed from this starter is invisible to
Muse's skill search and skill list.

This script derives each descriptor from the skill's existing Claude Code
frontmatter (`name` / `description`), so the two formats stay in sync:

  name              folder name, snake_cased (Muse requires snake_case
                    matching the folder, e.g. folder `ai-seo` -> `ai_seo`)
  title             folder name, humanized
  description       the frontmatter description, folded to one line
  category          "Work and knowledge" (edit per skill if you curate)
  include_in_prompt false — a starter library is discovered via skill
                    search, not injected into every conversation

Usage: python3 scripts/generate-skill-yaml.py [--force]
Existing skill.yaml files are kept unless --force is given.
No third-party dependencies.
"""

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SKILLS_DIR = ROOT / "skills"
DEFAULT_CATEGORY = "Work and knowledge"


def parse_frontmatter(text: str) -> dict:
    """Minimal frontmatter reader: top-level `key: value` pairs, with
    indented continuation lines folded into the previous value and
    surrounding quotes stripped. Enough for SKILL.md frontmatter."""
    if not text.startswith("---"):
        return {}
    end = text.find("\n---", 3)
    if end == -1:
        return {}
    block = text[3:end]
    data: dict[str, str] = {}
    current = None
    for line in block.splitlines():
        m = re.match(r"^([A-Za-z0-9_-]+):\s*(.*)$", line)
        if m and not line.startswith((" ", "\t")):
            current = m.group(1)
            data[current] = m.group(2).strip()
        elif current is not None and line.strip():
            data[current] = (data[current] + " " + line.strip()).strip()
    for key, value in data.items():
        if len(value) >= 2 and value[0] == value[-1] and value[0] in "\"'":
            value = value[1:-1]
        data[key] = re.sub(r"\s+", " ", value).strip()
    return data


def snake_case(folder: str) -> str:
    name = re.sub(r"[^a-z0-9]+", "_", folder.lower()).strip("_")
    return name or "skill"


def humanize(folder: str) -> str:
    return " ".join(w.capitalize() for w in re.split(r"[-_]+", folder) if w)


def q(value: str) -> str:
    """JSON-style double-quoted scalar — valid YAML and escaping-safe."""
    return json.dumps(value, ensure_ascii=False)


def main() -> int:
    force = "--force" in sys.argv
    written, kept, problems = 0, 0, []
    seen_names: dict[str, str] = {}
    for skill_md in sorted(SKILLS_DIR.rglob("SKILL.md")):
        folder = skill_md.parent
        target = folder / "skill.yaml"
        if target.exists() and not force:
            kept += 1
            continue
        fm = parse_frontmatter(skill_md.read_text(encoding="utf-8"))
        description = fm.get("description", "")
        if not description:
            problems.append(f"{folder.relative_to(ROOT)}: no frontmatter description")
            continue
        name = snake_case(folder.name)
        if name in seen_names:
            problems.append(
                f"{folder.relative_to(ROOT)}: name {name!r} collides with {seen_names[name]}"
            )
            continue
        seen_names[name] = str(folder.relative_to(ROOT))
        target.write_text(
            "\n".join(
                [
                    f"name: {q(name)}",
                    f"title: {q(humanize(folder.name))}",
                    f"description: {q(description)}",
                    f"category: {q(DEFAULT_CATEGORY)}",
                    "include_in_prompt: false",
                    "",
                ]
            ),
            encoding="utf-8",
        )
        written += 1
    print(f"skill.yaml written: {written}, kept existing: {kept}")
    for p in problems:
        print(f"PROBLEM: {p}")
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
