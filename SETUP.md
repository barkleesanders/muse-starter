# Setup — make this starter a working copy of the reference setup

This starter is a de-personalized copy of one real working setup: the
same skills, the same tracker, and the same tool belt, with all personal
information, personal/case-specific skills, credentials, and machine
configuration removed. Installing the files is only step one — the
skills assume the tracker and tools below are present. Install them.

## 1. Install the files

```bash
git clone https://github.com/barkleesanders/muse-starter.git
cd muse-starter
./install.sh                 # discoverable subset (safe default)
./install.sh --mode activate # the full copy: every skill discoverable
```

See the README's install-modes table for what each mode does, and run
`./install.sh --preflight` first if you already run a system of your own.

## 2. Install beads — this setup's task tracker

The workflow skills (`code`, `goal`, `taskmaster`, `loop-runner`,
`ship`, …) are written against [beads](https://github.com/steveyegge/beads)
(`bd`), a Dolt-backed issue tracker for agents. Without it, those skills
degrade to chat-only tracking. Install it and initialize it per project:

```bash
# macOS / Linux
brew install beads
# or, without Homebrew:
curl -fsSL https://raw.githubusercontent.com/steveyegge/beads/main/scripts/install.sh | bash

cd your-project
bd init
```

Full guide: [BEADS.md](BEADS.md).

**The one exception:** if you already run a task tracker or a shared
work record, keep yours and skip beads. Two trackers create a second
source of truth — that warning is for people merging this pack into an
existing system, not for fresh setups following it as their system.

## 3. Install the core tools

The skills shell out to a small core tool belt. Counts are how many of
the 139 skills reference each tool (from MANIFEST.json):

| Tool | Used by | macOS (brew) | Linux (apt / other) |
|---|---|---|---|
| `git` | 36 skills | `brew install git` | `apt install git` |
| `curl` | 41 skills | preinstalled | `apt install curl` |
| `node` + `npm`/`npx` | 26 skills | `brew install node` | [NodeSource](https://github.com/nodesource/distributions) or `apt install nodejs npm` |
| `python3` | 26 skills | `brew install python` | `apt install python3` |
| `jq` | 23 skills | `brew install jq` | `apt install jq` |
| `gh` (GitHub CLI) | 16 skills | `brew install gh` | [cli.github.com](https://cli.github.com) |
| `bd` (beads) | 14 skills | `brew install beads` | install script, step 2 |
| `wrangler` (Cloudflare) | 11 skills | `npm i -g wrangler` | `npm i -g wrangler` |
| `stripe` CLI | 12 skills | `brew install stripe/stripe-cli/stripe` | [stripe.com/docs/stripe-cli](https://stripe.com/docs/stripe-cli) |
| `ffmpeg` | 4 skills | `brew install ffmpeg` | `apt install ffmpeg` |
| `rclone` | 3 skills | `brew install rclone` | `apt install rclone` |

Or run the helper — it prints every command first and installs only
with `--yes`:

```bash
bash scripts/install-tools.sh          # dry run: print the commands
bash scripts/install-tools.sh --yes    # actually install beads + core tools
```

Platform notes: several skills are macOS-oriented (Xcode/`xcodebuild`,
`osascript`, `launchctl` — 7–8 skills). On a Linux VM those skills are
reference material; run the Mac-specific work on a Mac. MANIFEST.json
flags the macOS signals per skill.

## 4. Per-skill extras

Beyond the core belt, individual skills reference specialized tools
(Ghidra for `decompile`, the Stripe CLI for payments skills, Vercel's
CLI, and so on). You do not need them all up front — install a skill's
extras when you first use that skill. The exact per-skill list is in
[MANIFEST.json](MANIFEST.json) under `tools_referenced`, and it is the
authoritative list: it is generated from the skills themselves by
`scripts/generate-manifest.py`.

## What is deliberately NOT in the copy

Personal and case-specific skills, real identity files (the templates
are generic starters), credentials, browser state, and machine-local
configuration stay private. Everything else — skills, agents, commands,
tracker, and tools — is the setup as it actually runs.
