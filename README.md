# Muse Starter

A portable, privacy-screened starter pack for Muse: reusable engineering
skills, specialist agents, and command templates — plus starter identity
files so a new Muse is set up the way this one is designed.

## Install

```bash
git clone https://github.com/barkleesanders/muse-starter.git
cd muse-starter
./install.sh --preflight   # report-only: see what conflicts with your existing system
./install.sh               # default mode: discoverable
```

The installer is designed to land on machines that **already have a
system on them** — an existing foundation/config document, a task
tracker, scheduled jobs, separate assistant roles. It runs a preflight
scan first and reports conflicts (existing identity files, an existing
beads tracker, existing scheduled jobs, skills already present) before
copying anything, and it never overwrites your existing identity files.

### Install modes

| Mode | What happens |
|---|---|
| `--mode files-only` | All skills copied to `~/workspace/skills/` as a reading library. **Nothing is discoverable** — Muse skill search only scans `~/workspace/custom-skills/`. |
| `--mode discoverable` (default) | Skills [`MANIFEST.json`](MANIFEST.json) marks safe/review go to `~/workspace/custom-skills/` (discoverable). Skills flagged **opt-in** — they create state, run on a schedule, can spend or deploy, or control the machine — are filed as a library only and **listed by name** in the install summary. |
| `--mode activate` | Every skill becomes discoverable. The opt-in skills being activated are listed before anything is copied. |
| `--activate goal,ship` | Activate named opt-in skills in any mode. |
| `--strict` | Also hold back "review" skills (they need an API key or can send) in discoverable mode. |

After copying, the installer runs a **discovery test**: every
discoverable skill must have `SKILL.md` + `skill.yaml` in
`~/workspace/custom-skills/`, and the result is printed as a count. The
final summary states plainly what was installed as **files**, what
became **discoverable**, and that **no external tools were installed
and no state was activated** — the installer copies files only, and
creates no tracker, schedule, or service.

| Repo path | Install target | Notes |
|---|---|---|
| `skills/` (safe/review) | `~/workspace/custom-skills/` | Discovered by Muse's skill search |
| `skills/` (opt-in, not activated) | `~/workspace/skills/` | Library only — not discoverable |
| `agents/` | `~/workspace/agents/` | Specialist briefs (see `agents/`) |
| `commands/` | `~/workspace/commands/` | Prompt templates (see `commands/`) |
| `MUSE.md` | `~/workspace/MUSE.md` | Only if absent |
| `templates/*` | `~/SOUL.md`, `~/USER.md`, … | Only if absent; never overwrites |

Set `MUSE_WORKSPACE` to install the workspace parts somewhere other than
`~/workspace`.

### Then: install the tracker and the tools

The files alone are not the setup — the skills assume **beads (`bd`)**
and a small core tool belt (`git`, `node`, `python3`, `jq`, `gh`,
`wrangler`, …) are installed. [SETUP.md](SETUP.md) is the full flow:
beads install, the tool table with macOS/Linux commands, an install
helper (`scripts/install-tools.sh`, dry-run by default), and the
per-skill extras list in MANIFEST.json.

### What each skill needs: MANIFEST.json

[`MANIFEST.json`](MANIFEST.json) is a generated per-skill manifest —
external tools referenced (referenced only, never installed), API
keys/env vars, macOS signals (many install notes in the skills are
brew/macOS-oriented; on a Linux VM, treat those steps as Mac-side),
references to the private `shared/` layer this repo does not ship
(19 skills), references to Claude Code `~/.claude/` paths (63 skills —
dead ends on a Muse-only system), and the activation flags above.
Regenerate it with `python3 scripts/generate-manifest.py`; verify the
installer contract with `bash scripts/check-installer.sh` and
`bash scripts/test-install.sh`.

## What's inside

- **139 skills** — engineering workflows (`carmack`, `debug`, `ship`), research,
  government accountability (`gov`), marketing, SEO, mobile, and more. Each skill is a `SKILL.md`
  plus a generated `skill.yaml` descriptor, which is what Muse's skill
  search reads, plus supporting `references/`, `scripts/`, `tools/`, and
  `bin/` files.
- **36 agents** — specialist briefs (code reviewer, security sentinel,
  architecture strategist, …). In Muse, spawn a subagent with the file's
  content as the task brief.
- **22 commands** — prompt templates for recurring workflows (triage,
  release docs, bug reproduction, …). Paste one into chat or ask Muse to
  run it.
- **Identity templates** — starter `SOUL.md`, `USER.md`, `MEMORY.md`,
  `AGENTS.md`, `TOOLS.md`, and `IDENTITY.md`: the standing files this
  setup is designed around.
- **Beads task tracking** — [`BEADS.md`](BEADS.md) sets up `bd`, the
  Dolt-backed tracker this setup runs on; the workflow skills assume
  it. **Install it as part of [SETUP.md](SETUP.md)** — the starter is a
  working copy of the reference setup, tracker and tools included. The
  one exception: if you already run a task system (a work record,
  shared reminders, another tracker), keep yours and skip beads — a
  second tracker is a second source of truth. [`SHARE.md`](SHARE.md)
  is a short copy-paste blurb for handing this starter to someone.

## Roles, hooks, and other honest deltas

- **One-assistant assumptions.** Skills like `ship`, `code`, and
  `computeruse` are written as if one assistant builds, deploys, and
  controls the machine. If your setup separates those roles (builder /
  deployer / checker), treat those skills as opt-in (the installer does)
  and map them to your own seats before activating.
- **Claude Code hooks do not port.** The `goal` skill's per-message
  steering depends on a Claude Code `UserPromptSubmit` injector hook
  that is **not included** in this pack and has no Muse equivalent in
  the pack; the goal ledger works, the steering does not. `taskmaster`
  and `loop-runner` hooks are likewise reference-only. Standing loops
  belong in your own scheduler/jobs list, not in this pack.
- **The private `shared/` layer.** 19 skills reference
  `~/workspace/skills/shared/`, which ships only with a private
  companion kit. Those references are dead ends without it;
  MANIFEST.json names every affected skill.

## Claude Code heritage

This starter was converted from a Claude Code starter pack. `PORTING.md`
documents exactly what was rewritten (install paths), what was left alone
(Claude Code runtime paths some skills interoperate with), and the known
deltas (lifecycle hooks, model hints, the private `shared/` companion).

## Boundary

Personal and case-specific skills are intentionally kept in a separate
private repository and are never generated into this public repository.
Keep additions generic, portable, and free of personal information.
