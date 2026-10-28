# Claude Code → Muse porting notes

This starter was converted from the `claude-code-starter` pack. Two
structural differences from Claude Code matter, and both are easy to get
wrong because a wrong install *looks* installed:

1. **Discovery folder.** Muse scans `~/workspace/custom-skills/` for
   custom skills — not `~/workspace/skills/`. Skills copied anywhere else
   are invisible to skill search. (`install.sh` targets
   `~/workspace/custom-skills/`; the first port targeted
   `~/workspace/skills/` and silently installed nothing discoverable.)
2. **Skill descriptor.** Muse identifies a skill by the `skill.yaml`
   beside its `SKILL.md` — `name` (snake_case, matching the folder),
   `title`, `description`, `category`, `include_in_prompt` — not by the
   Claude Code frontmatter inside `SKILL.md`. Every skill in this repo
   ships a generated `skill.yaml` next to its `SKILL.md`; the frontmatter
   is retained so the same files still work in Claude Code. Regenerate
   the descriptors after adding or editing skills with
   `python3 scripts/generate-skill-yaml.py`. Generated descriptors use
   `include_in_prompt: false`: a starter library is found via skill
   search, not injected into every conversation.

## Mechanical rewrites (applied by `convert.py`)

| Claude Code original | Muse starter |
|---|---|
| `~/.claude/skills/` | `~/workspace/custom-skills/` |
| `~/.claude/agents/` | `~/workspace/agents/` |
| `~/.claude/CLAUDE.md` | `~/workspace/MUSE.md` |
| `model: sonnet/haiku/inherit` in `agents/*.md` frontmatter | removed — Muse selects the model at subagent spawn time |
| Claude Code `SKILL.md` frontmatter as the only descriptor | a `skill.yaml` generated beside every `SKILL.md` (`scripts/generate-skill-yaml.py`) |

## Intentionally unchanged

Paths under `~/.claude/` that describe **Claude Code's own runtime** were
left as-is, because they refer to Claude Code itself — not to this
starter's install location:

- `~/.claude/projects/` — Claude Code session transcripts (used by
  `token-usage` and `printing-press-amend`). These skills keep working
  against a Claude Code installation alongside Muse.
- `~/.claude/settings.json` — Claude Code settings incl. lifecycle hooks
  (referenced by `taskmaster`, `design`, `ship`).
- `~/.claude/state/`, `~/.claude/logs/`, `~/.claude/plugins/`,
  `~/.claude/usage/`, `~/.claude.json` — Claude Code runtime state.

## Known deltas

- **Lifecycle hooks.** Claude Code `UserPromptSubmit` / `Stop` hooks
  (`taskmaster`, `loop-runner`) have no equivalent in this starter; the
  hook scripts are included for reference. Muse-native scheduling
  (crons) and event hooks are the replacement — wire them per your setup.
- **`skills/shared/` references.** About two dozen cross-references point
  at `~/workspace/custom-skills/shared/`, which ships only with the private
  companion kit and is intentionally excluded from this public repo. They
  resolve once the companion kit is installed; until then treat them as
  optional deep-reference links.
- **Plugin-scoped commands.** A few command templates reference plugin
  commands not included here (e.g. `lfg.md` references `ralph-loop` and
  `workflows:` / `compound-engineering:` plugins). They are kept as
  templates; adapt the steps to your environment.
- **Agents as briefs.** Each file in `agents/` is a specialist system
  brief. In Muse there is no agents registry — spawn a subagent with the
  file's content as the task brief (see `agents/README.md`).
