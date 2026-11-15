# Claude Code → Muse porting notes

This starter was converted from the `claude-code-starter` pack. The skill
frontmatter format (`name`, `description`, plus `user-invocable` /
`allowed-tools` where present) is already Muse-compatible, so skills needed
no structural changes — only install-path rewrites.

## Discovery: the two rules that decide whether anything works

1. **Discovery folder.** Muse scans `~/workspace/custom-skills/` for
   custom skills — not `~/workspace/skills/`. Skills copied anywhere else
   are invisible to skill search, however complete the copy looks.
   (`~/workspace/skills/` is used by the installer only as a files-only
   library for opt-in skills that were not activated.)
2. **Skill descriptor.** Muse identifies a skill by the `skill.yaml`
   beside its `SKILL.md` (`name`, `title`, `description`, `category`,
   `include_in_prompt`) — not by the Claude Code frontmatter inside
   `SKILL.md`. Every skill ships a generated `skill.yaml`; regenerate
   with `python3 scripts/generate-skill-yaml.py`.

An earlier port got rule 1 wrong, a later refresh accidentally restored
the wrong target, and both times the pack "installed" silently. The
regression guard `scripts/check-installer.sh` and the sandbox test
`scripts/test-install.sh` now pin the contract.

## Mechanical rewrites (applied by `convert.py`)

| Claude Code original | Muse starter |
|---|---|
| `~/.claude/skills/` | `~/workspace/custom-skills/` |
| `~/.claude/agents/` | `~/workspace/agents/` |
| `~/.claude/CLAUDE.md` | `~/workspace/MUSE.md` |
| `model: sonnet/haiku/inherit` in `agents/*.md` frontmatter | removed — Muse selects the model at subagent spawn time |
| Claude Code `SKILL.md` frontmatter as the only descriptor | a `skill.yaml` generated beside every `SKILL.md` |

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

- **Lifecycle hooks do not port.** Claude Code `UserPromptSubmit` /
  `Stop` hooks have no Muse equivalent in this pack. Concretely: the
  `goal` skill's ledger and scripts ship, but the `goal-injector.sh`
  hook that steers every message in Claude Code is **not included** —
  on Muse the ledger works and the per-message steering does not.
  `taskmaster` and `loop-runner` hook scripts are included for
  reference only. Muse-native scheduling (crons) and event hooks are
  the replacement — wire them per your setup, and register any standing
  loop in your own jobs list: this pack creates no schedules.
- **Trackers do not stack.** `goal`, `taskmaster`, and beads (`bd`) each
  bring their own task state. If you already run a tracker or a shared
  work record, leave all three off (the installer holds them back as
  opt-in) — running two trackers creates a second source of truth.
- **`skills/shared/` references.** 19 skills cross-reference
  `~/workspace/skills/shared/`, which ships only with the private
  companion kit and is intentionally excluded from this public repo.
  They resolve once the companion kit is installed; until then they are
  dead ends. MANIFEST.json (`shared_layer_skills`) names all 19.
- **`~/.claude/` references.** 63 skills reference Claude Code paths
  (transcripts, settings, state). On a Muse-only system those are dead
  ends too; MANIFEST.json (`claude_code_ref_skills`) names them.
- **Plugin-scoped commands.** A few command templates reference plugin
  commands not included here (e.g. `lfg.md` references `ralph-loop` and
  `workflows:` / `compound-engineering:` plugins). They are kept as
  templates; adapt the steps to your environment.
- **Agents as briefs.** Each file in `agents/` is a specialist system
  brief. In Muse there is no agents registry — spawn a subagent with the
  file's content as the task brief (see `agents/README.md`).

## 2026-11 refresh

- Re-converted from the then-current `claude-code-starter` source with the
  same mechanical rules above; no skill was hand-edited in the conversion.
- Added 20 skills that originated on the Muse side (they had no Claude
  Code counterpart): animate, apple-design, expense-ledger,
  command-builder-pro, csv-link-validator, debugging-genius, doc-maker,
  glean-connector-reviewer, interview-prep, it-project-report-assistant,
  json-structurer, professional-text-editor, prompt-architect,
  career-interview-prep, career-resume-optimizer, career-success-coach,
  html-report, cn-ecommerce-search, x-cli, and worker-queue-bridge.
  Before publication these went through the same privacy screen as the
  rest of the pack, plus a mechanical de-personalization pass: owner
  names, personal handles and account IDs, personal email addresses, and
  machine-specific "house rules" headers were replaced with generic
  equivalents ("the user", "your machine"). No other content was changed.
- Personal, case-specific, and infrastructure-bound skills remain in the
  private repositories only, per the Boundary note in the README.
