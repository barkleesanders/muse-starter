# Beads — task tracking for this setup

Beads is the tracker the reference setup runs on, and this starter is a
copy of that setup: **install beads as part of [SETUP.md](SETUP.md)**
unless the exception below applies to you.

> **The one exception — read this if you already track work somewhere.**
> If you already run a task system — a shared work record, shared
> reminders, another tracker — **do not enable beads on top of it.**
> Two trackers means a second source of truth, and work will silently
> split across them. Pick ONE tracker: yours, or this one. (The `goal`
> ledger and `taskmaster` in this pack mirror into beads; they are not
> separate trackers to run in parallel with yours either.)

[Beads](https://github.com/steveyegge/beads) (`bd`) is a Dolt-powered issue
tracker built for AI coding agents. It gives your assistant persistent,
structured memory of every task — no more losing track of work between
sessions. Several skills (`code`, `ship`, `loop-runner`, `taskmaster`)
reference `bd` commands; those references are inert until you install
and initialize beads yourself — the starter installer never does.

## Install

```bash
# macOS / Linux
brew install beads
# or
curl -fsSL https://raw.githubusercontent.com/steveyegge/beads/main/scripts/install.sh | bash
```

## Initialize in your project

```bash
cd your-project
bd init
```

This creates a `.beads/` directory (Dolt database) inside the project —
commit it with your repo so task history travels with the code.

## Daily commands

```bash
bd create "Add user authentication" -p 1 -t task   # new bead
bd list                                              # all beads
bd ready                                             # unblocked work only
bd update <id> --status in_progress                   # claim it
bd close <id> --reason "what was done"               # close with evidence
```

## If you adopt beads: the standing rule

**Every task gets a bead, and a bead closes only with cited evidence.**
This rule applies only inside a beads-based setup. If your existing
system has its own rule for what earns a record, that rule wins and
this section does not apply.
