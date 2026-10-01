# Muse Starter

A portable, privacy-screened starter pack for Muse: reusable engineering
skills, specialist agents, and command templates — plus starter identity
files so a new Muse is set up the way this one is designed.

## Install

```bash
git clone https://github.com/barkleesanders/claude-code-starter.git
cd claude-code-starter
./install.sh
```

The installer copies the curated public files into your Muse environment. It
never overwrites your existing files:

| Repo path      | Install target                    | Notes                                  |
|----------------|-----------------------------------|----------------------------------------|
| `skills/`      | `~/workspace/skills/`             | Auto-discovered by Muse's skill search |
| `agents/`      | `~/workspace/agents/`             | Specialist briefs (see `agents/`)      |
| `commands/`    | `~/workspace/commands/`           | Prompt templates (see `commands/`)     |
| `MUSE.md`      | `~/workspace/MUSE.md`             | Only if absent                         |
| `templates/*`  | `~/SOUL.md`, `~/USER.md`, …       | Only if absent; never overwrites       |

Set `MUSE_WORKSPACE` to install the workspace parts somewhere other than
`~/workspace`.

## What's inside

- **84 skills** — engineering workflows (`code`, `debug`, `ship`), research,
  marketing, SEO, mobile, and more. Each skill is a `SKILL.md` with
  frontmatter (`name`, `description`) that Muse's skill search discovers
  automatically, plus supporting `references/`, `scripts/`, `tools/`, and
  `bin/` files.
- **35 agents** — specialist briefs (code reviewer, security sentinel,
  architecture strategist, …). In Muse, spawn a subagent with the file's
  content as the task brief.
- **21 commands** — prompt templates for recurring workflows (triage,
  release docs, bug reproduction, …). Paste one into chat or ask Muse to
  run it.
- **Identity templates** — starter `SOUL.md`, `USER.md`, `MEMORY.md`,
  `AGENTS.md`, `TOOLS.md`, and `IDENTITY.md`: the standing files this
  setup is designed around.
- **Beads task tracking** — [`BEADS.md`](BEADS.md) sets up `bd`, the
  Dolt-backed tracker several skills assume. [`SHARE.md`](SHARE.md) is a
  short copy-paste blurb for handing this starter to someone.

## Claude Code heritage

This starter was converted from a Claude Code starter pack. `PORTING.md`
documents exactly what was rewritten (install paths), what was left alone
(Claude Code runtime paths some skills interoperate with), and the known
deltas (lifecycle hooks, model hints, the private `shared/` companion).

## Boundary

Personal and case-specific skills are intentionally kept in a separate
private repository and are never generated into this public repository.
Keep additions generic, portable, and free of personal information.
