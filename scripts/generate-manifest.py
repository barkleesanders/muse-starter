#!/usr/bin/env python3
"""Generate MANIFEST.json — a per-skill dependency & activation manifest.

Why this exists: a starter pack that assumes it is the only system on the
machine will silently collide with an existing setup (a second task
tracker, standing jobs, a shared layer that is not included). This
manifest makes every skill's requirements visible BEFORE install:

  - external tools it references (referenced, NOT installed by install.sh)
  - environment variables / API keys it mentions
  - platform signals (e.g. brew / osascript = macOS-oriented)
  - references to the private shared layer (skills/shared/) that this
    public repo does not ship
  - references to Claude Code paths (~/.claude/...) that are dead ends
    on a Muse-only system
  - activation flags: creates_state, scheduled, needs_key, can_spend,
    can_send, can_deploy, controls_machine. A skill with ANY flag set is
    "opt-in": install.sh files it but does not make it discoverable
    until the user activates it explicitly.

Flags are heuristic plus a small hand-reviewed OVERRIDES table for
skills whose surface keywords mislead. Flag patterns scan SKILL.md (the
skill's own stated behavior) — not references/, whose deep docs mention
every tool and action in passing and would flag nearly every skill.
Reference-integrity counts (shared-layer and ~/.claude references) and
the tools list scan the whole skill tree, because a dead reference in a
reference file is still a dead end for the reader. The manifest is
generated, never hand-edited — rerun after adding or editing skills:

    python3 scripts/generate-manifest.py
"""
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SKILLS = ROOT / "skills"

TEXT_SUFFIXES = {".md", ".sh", ".py", ".yaml", ".yml", ".txt", ".json", ".toml"}

CURATED_TOOLS = [
    "git", "gh", "node", "npm", "npx", "python3", "pip3", "ffmpeg",
    "ghidra", "rclone", "wrangler", "bd", "jq", "curl", "docker",
    "kubectl", "xcodebuild", "osascript", "launchctl", "crontab",
    "cua", "peekaboo", "stripe", "vercel", "flyctl",
]

ENV_RE = re.compile(r"\b[A-Z][A-Z0-9_]*_(?:API_KEY|ACCESS_TOKEN|SECRET|PRIVATE_KEY|TOKEN)\b")
BREW_RE = re.compile(r"brew install (?:--cask )?([a-zA-Z0-9@._+-]+)")
SHARED_RE = re.compile(r"skills/shared/")
CLAUDE_RE = re.compile(r"\.claude/")
MACOS_SIGNALS = ["brew", "homebrew", "osascript", "launchd", "launchagent",
                 "xcodebuild", "macos", "apple script", "applescript"]

FLAG_PATTERNS = {
    "creates_state": [r"\bbd create\b", r"\.beads\b", r"taskmaster",
                      r"goal\.sh", r"state file", r"task tracker",
                      r"issue tracker"],
    "scheduled": [r"\bcron\b", r"launchagent", r"launchd", r"scheduled task",
                  r"standing job", r"recurring (job|task|check)"],
    "can_spend": [r"\bpurchase\b", r"buy now", r"\bcheckout\b",
                  r"place (an )?order", r"payment method", r"credit card",
                  r"paid ads", r"ad spend"],
    "can_send": [r"send (an? )?(email|message|fax|sms)", r"send_email",
                 r"sends? .{0,30}(email|mail|message|fax)",
                 r"post to (x|twitter|instagram|facebook)"],
    "can_deploy": [r"wrangler deploy", r"/ship\b", r"\bship it\b",
                   r"deploy(s|ing|ment)? .{0,40}(production|prod|live)"],
    "controls_machine": [r"computer ?use", r"osascript", r"\bcua\b",
                         r"gui (automation|control)", r"control(s)? the (mac|machine|computer)"],
}

# Hand-reviewed corrections where keyword surface misleads. Keep small and
# say why, here, so the next reader trusts the rest of the table.
OVERRIDES = {
    # Watches credit balances and reports; it never spends.
    "ai-credit-watch": {"can_spend": False},
    # The goal/taskmaster pair create tracker state by design.
    "goal": {"creates_state": True},
    "taskmaster": {"creates_state": True, "scheduled": True},
    # "ship it" appears only inside quoted devil's-advocate probe lines;
    # the tutor edits skill text and never deploys anything.
    "ai-tutor": {"can_deploy": False},
}

# Hard gate: skills with any of these change the *system* they land on —
# they create tracker/state stores, stand up schedules, spend, deploy, or
# drive the machine. install.sh files them but does not make them
# discoverable until the user activates them by name.
GATE_FLAGS = ["creates_state", "scheduled", "can_spend",
              "can_deploy", "controls_machine"]
# Soft gate: recorded and surfaced in the install summary, but the skill
# is inert text until invoked, so it installs discoverable. `--strict`
# holds these back too.
SOFT_FLAGS = ["needs_key", "can_send"]


def skill_text(skill_dir: Path) -> str:
    parts = []
    for p in sorted(skill_dir.rglob("*")):
        if p.is_file() and p.suffix in TEXT_SUFFIXES and p.stat().st_size < 2_000_000:
            try:
                parts.append(p.read_text(errors="ignore"))
            except OSError:
                pass
    return "\n".join(parts)


def main() -> int:
    skills = {}
    for skill_dir in sorted(p for p in SKILLS.iterdir() if p.is_dir()):
        name = skill_dir.name
        text = skill_text(skill_dir)
        skill_md = skill_dir / "SKILL.md"
        primary = skill_md.read_text(errors="ignore") if skill_md.exists() else ""
        lower = primary.lower()

        tools = sorted({t for t in CURATED_TOOLS
                        if re.search(rf"(?<![\w-]){re.escape(t)}(?![\w-])", text)})
        brew = sorted(set(BREW_RE.findall(text)))
        for b in brew:
            if b not in tools:
                tools.append(b)
        tools.sort()

        flags = {}
        for flag, pats in FLAG_PATTERNS.items():
            flags[flag] = any(re.search(p, lower) for p in pats)
        env = sorted(set(ENV_RE.findall(primary)))
        flags["needs_key"] = bool(env)
        for flag, val in OVERRIDES.get(name, {}).items():
            flags[flag] = val

        files = sorted(str(p.relative_to(skill_dir))
                       for p in skill_dir.rglob("*") if p.is_file())
        entry = {
            "description": "",
            "files": {
                "skill_md": (skill_dir / "SKILL.md").exists(),
                "skill_yaml": (skill_dir / "skill.yaml").exists(),
                "ships_executable_files": any(
                    (skill_dir / d).is_dir() for d in ("scripts", "tools", "bin", "hooks")),
                "file_count": len(files),
            },
            "tools_referenced": tools,
            "tools_note": "Referenced only — install.sh installs files, never external tools.",
            "env_or_keys": env,
            "macos_signals": sorted({s for s in MACOS_SIGNALS if s in lower}),
            "shared_layer_refs": len(SHARED_RE.findall(text)),
            "claude_code_refs": len(CLAUDE_RE.findall(text)),
            "flags": flags,
            "gate_reasons": [f for f in GATE_FLAGS if flags[f]],
            "activation": ("opt-in" if any(flags[f] for f in GATE_FLAGS)
                           else "review" if any(flags[f] for f in SOFT_FLAGS)
                           else "safe"),
        }
        yaml_path = skill_dir / "skill.yaml"
        if yaml_path.exists():
            m = re.search(r"^description:\s*(.+)$", yaml_path.read_text(errors="ignore"), re.M)
            if m:
                entry["description"] = m.group(1).strip().strip('"')
        skills[name] = entry

    manifest = {
        "schema_version": 1,
        "generated_by": "scripts/generate-manifest.py — do not hand-edit",
        "skill_count": len(skills),
        "opt_in_count": sum(1 for s in skills.values() if s["activation"] == "opt-in"),
        "review_count": sum(1 for s in skills.values() if s["activation"] == "review"),
        "shared_layer_skills": sorted(n for n, s in skills.items() if s["shared_layer_refs"]),
        "claude_code_ref_skills": sorted(n for n, s in skills.items() if s["claude_code_refs"]),
        "skills": skills,
    }
    out = ROOT / "MANIFEST.json"
    out.write_text(json.dumps(manifest, indent=2, sort_keys=True) + "\n")
    print(f"MANIFEST.json: {manifest['skill_count']} skills, "
          f"{manifest['opt_in_count']} opt-in, {manifest['review_count']} review, "
          f"{len(manifest['shared_layer_skills'])} reference the private shared layer, "
          f"{len(manifest['claude_code_ref_skills'])} reference ~/.claude paths")
    return 0


if __name__ == "__main__":
    sys.exit(main())
