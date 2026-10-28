# Muse Starter Configuration

Use evidence before conclusions, preserve user work, and verify behavior
before calling a change complete. Track project work in the project's own
task system.

## Git safety

Run `git status` before state-changing Git commands. Never reset, clean,
force push, or overwrite unrelated work without explicit approval.

## Engineering workflow

- Use `/code` for implementation and evidence-based debugging.
- Use `/debug` for a structured root-cause investigation.
- Use `/ship` only when the user authorizes deployment.
- Keep fixes minimal and add regression coverage for corrected behavior.

## Muse layout

- **Skills** live in `~/workspace/custom-skills/` — the only folder Muse
  scans for custom skills — and are discovered by skill search on the
  `name` and `description` in each skill's `skill.yaml` descriptor (kept
  beside its `SKILL.md`). Keep `SKILL.md` focused; put bulky docs in
  `references/`.
- **Agents** in `~/workspace/agents/` are specialist briefs. Spawn a
  subagent with the file's content as the task brief.
- **Commands** in `~/workspace/commands/` are prompt templates. Paste one
  into chat or ask Muse to run it.

## Public configuration boundary

This starter intentionally excludes personal, case-specific, health,
benefits, legal-advocacy, credentials, browser state, and machine-local
configuration.
