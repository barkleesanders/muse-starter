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

- **140 skills** — engineering workflows (`carmack`, `debug`, `ship`), research,
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

## The AI Tutor — skills that tutor themselves

Skills rot. A workflow that read well the day it was written quietly
stops matching the tools, routes, and failure modes around it, and the
agent improvises the difference. The [`ai-tutor`](skills/ai-tutor/SKILL.md)
skill is this pack's answer: a recursive self-tutoring loop, adapted
from Jane Street's `socratic-tutor`, in which **the student is the
skill itself**.

How it works:

- **Diagnose before editing.** The target skill is decomposed into
  4–10 sub-capabilities (trigger precision, procedure correctness,
  failure handling, boundary discipline, …), each graded on a 0–5
  scale. The baseline is earned by **probes**: fresh-context agents
  that see only the `SKILL.md` and a task input, and execute the
  procedure for real — real tools, real read-backs — stopping only at
  the skill's own approval gates. Paper probes (reading the text and
  narrating what it *would* do) cap a sub-capability at 3.
- **One gap, one edit, one re-test.** The loop works weakest-first:
  name the single gap a failing probe exposed, make the minimal edit
  that closes exactly it, then re-test from a different angle, with a
  devil's-advocate probe on every pass trying to break the fix.
- **A final assessment is the ship gate.** Every sub-capability at
  target (4 by default, 5 for safety/credential/payment-adjacent
  skills), a fresh mixed probe set, and a proved / not-proved line in
  the report. Fail, and the loop continues.

How it scales:

- **The registry persists.** Skill maps live in the tutor's own
  `state/` directory, so levels survive across sessions — and are
  re-tested, not trusted. Every tutor run ends with **spaced review**:
  up to two previously tutored skills get a fresh unprompted probe,
  and a regression lowers the recorded level on the spot. A map stale
  for 60+ days is reported UNVERIFIED, whatever it says.
- **It scales down as well as up.** A one-line skill fix gets a
  two-probe micro-loop, not the full assessment — the loop shrinks; it
  does not switch off.
- **Real failures feed it.** Tool failures and workarounds from daily
  work are filed as structured feedback records and swept by a
  deterministic harvester into a ledger the tutor triages by
  mechanism. Feedback opens a diagnostic; only a reproduced failure
  moves a level.
- **It applies to itself.** Any edit to the tutor's own `SKILL.md`
  goes through the loop with the tutor as the student.

The standards it grades against are part of the skill: mandatory
ladders for failure-prone flows (sign-ins, codes, payments, filings),
a no-arbitrary-limits rule (a cap that binds silently is data loss),
and Richard Cook's complex-systems failure discipline — TAC
decomposition instead of "root cause", sabotage-validated guards,
sunset/coupling accounting for every defence added.

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
