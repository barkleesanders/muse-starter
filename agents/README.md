# Agents

Each file in this directory is a specialist brief: frontmatter (`name`,
`description`, `tools`) plus a system prompt for a focused reviewer,
architect, researcher, or debugger.

Muse has no agents registry, so use a brief by spawning a subagent with the
file's content as the task brief. For example:

> Act as the specialist defined in `~/workspace/agents/code-reviewer.md`
> and review the diff on this branch.

The `model:` hint from the Claude Code original was removed during the
port — Muse selects the model when the subagent is spawned.
