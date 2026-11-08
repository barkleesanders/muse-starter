# Claude Code → Muse porting notes

This starter was converted from the `claude-code-starter` pack. The skill
frontmatter format (`name`, `description`, plus `user-invocable` /
`allowed-tools` where present) is already Muse-compatible, so skills needed
no structural changes — only install-path rewrites.

## Mechanical rewrites (applied by `convert.py`)

| Claude Code original | Muse starter |
|---|---|
| `~/.claude/skills/` | `~/workspace/skills/` |
| `~/.claude/agents/` | `~/workspace/agents/` |
| `~/.claude/CLAUDE.md` | `~/workspace/MUSE.md` |
| `model: sonnet/haiku/inherit` in `agents/*.md` frontmatter | removed — Muse selects the model at subagent spawn time |

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
  at `~/workspace/skills/shared/`, which ships only with the private
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
