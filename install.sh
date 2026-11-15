#!/usr/bin/env bash
#
# Muse Starter installer.
#
# This installer is built for machines that already have a system on
# them. It therefore does three things a plain copy would not:
#
#   1. PREFLIGHT — before copying anything, it reports what it found:
#      existing identity/foundation files, existing task trackers
#      (beads, taskmaster state), existing scheduled jobs, and skills
#      already present. Conflicts are reported, never silently merged.
#   2. MODES — you choose how much becomes active:
#        files-only    Copy everything to ~/workspace/skills/ as a
#                      library. NOTHING is discoverable by Muse skill
#                      search in this mode (Muse only searches
#                      ~/workspace/custom-skills/).
#        discoverable  (default) Skills MANIFEST.json marks "safe" or
#                      "review" go to ~/workspace/custom-skills/ where
#                      Muse skill search finds them. Skills flagged
#                      opt-in (they create state, run on a schedule,
#                      can spend / deploy, or control the machine) are
#                      filed as a library only and listed by name.
#        activate      Every skill goes to ~/workspace/custom-skills/.
#                      The opt-in skills being activated are listed
#                      before anything is copied.
#      --strict additionally holds back "review" skills (they need an
#      API key or can send) in discoverable mode.
#      --activate a,b  Activate named opt-in skills in any mode.
#   3. DISCOVERY TEST — after copying, every discoverable skill is
#      checked for the two files Muse discovery requires (SKILL.md +
#      skill.yaml) in ~/workspace/custom-skills/. The result is printed
#      as a count; a missing descriptor fails the install loudly.
#
# The installer copies FILES only. It never installs external tools
# (see MANIFEST.json per skill for what each skill references), never
# creates a tracker, schedule, or service, and never overwrites your
# existing identity files.
#
# Usage: ./install.sh [--mode files-only|discoverable|activate]
#                     [--activate skill,skill] [--strict]
#                     [--preflight] [--dry-run]
# Env:   MUSE_WORKSPACE (default: $HOME/workspace)
set -euo pipefail

SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WS="${MUSE_WORKSPACE:-$HOME/workspace}"
MODE="discoverable"
STRICT=0
DRY_RUN=0
PREFLIGHT_ONLY=0
ACTIVATE_LIST=""

while [ $# -gt 0 ]; do
  case "$1" in
    --mode) MODE="$2"; shift 2 ;;
    --mode=*) MODE="${1#--mode=}"; shift ;;
    --activate) ACTIVATE_LIST="$2"; shift 2 ;;
    --activate=*) ACTIVATE_LIST="${1#--activate=}"; shift ;;
    --strict) STRICT=1; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    --preflight) PREFLIGHT_ONLY=1; shift ;;
    -h|--help) sed -n '2,45p' "${BASH_SOURCE[0]}"; exit 0 ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
done
case "$MODE" in files-only|discoverable|activate) ;; *)
  echo "--mode must be files-only, discoverable, or activate" >&2; exit 2 ;;
esac

# --- Skill classification from MANIFEST.json (python3, with fallback) ---
SAFE_SKILLS=""; REVIEW_SKILLS=""; OPTIN_SKILLS=""
if [ -f "$SOURCE_DIR/MANIFEST.json" ] && command -v python3 >/dev/null 2>&1; then
  eval "$(python3 - "$SOURCE_DIR/MANIFEST.json" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
safe = [n for n, s in d["skills"].items() if s["activation"] == "safe"]
review = [n for n, s in d["skills"].items() if s["activation"] == "review"]
optin = [n for n, s in d["skills"].items() if s["activation"] == "opt-in"]
print(f'SAFE_SKILLS="{" ".join(sorted(safe))}"')
print(f'REVIEW_SKILLS="{" ".join(sorted(review))}"')
print(f'OPTIN_SKILLS="{" ".join(sorted(optin))}"')
PY
)"
else
  # Fallback if the manifest or python3 is unavailable: the tracker /
  # schedule / deploy / machine-control skills named in the docs are
  # held back; everything else is treated as safe.
  OPTIN_SKILLS="goal taskmaster loop-runner ship code computeruse exec-plan"
  echo "warning: MANIFEST.json or python3 not found — using fallback opt-in list" >&2
fi

in_list() { case " $2 " in *" $1 "*) return 0 ;; *) return 1 ;; esac; }
ACTIVATE_SPACED="$(echo "$ACTIVATE_LIST" | tr ',' ' ')"

# --- Preflight -------------------------------------------------------------
echo "== Preflight =="
echo "platform: $(uname -s) $(uname -m)   workspace: $WS   mode: $MODE"
CONFLICTS=0
for f in SOUL.md USER.md MEMORY.md AGENTS.md TOOLS.md IDENTITY.md; do
  if [ -e "$HOME/$f" ]; then
    echo "identity: ~/$f exists — kept, never overwritten"; CONFLICTS=$((CONFLICTS+1))
  fi
done
for f in "$WS/MUSE.md" "$WS/FOUNDATION.md" "$HOME/Foundation.md" "$WS/AGENTS.md"; do
  if [ -e "$f" ]; then
    echo "config: $f exists — an existing foundation/config is present; this pack will not replace it"
    CONFLICTS=$((CONFLICTS+1))
  fi
done
if command -v bd >/dev/null 2>&1 || [ -d "$PWD/.beads" ] || [ -d "$WS/.beads" ]; then
  echo "tracker: beads (bd) already present — do NOT enable this pack's goal/taskmaster/beads flow on top of an existing tracker"
  CONFLICTS=$((CONFLICTS+1))
fi
if [ -d "$WS/custom-skills" ] && [ -n "$(ls -A "$WS/custom-skills" 2>/dev/null)" ]; then
  echo "skills: $WS/custom-skills already holds $(ls "$WS/custom-skills" | wc -l | tr -d ' ') entries — new skills merge alongside them"
  CONFLICTS=$((CONFLICTS+1))
fi
if [ "$(uname -s)" = "Darwin" ]; then
  N=$(ls "$HOME/Library/LaunchAgents" 2>/dev/null | wc -l | tr -d ' ')
  if [ "$N" != "0" ]; then
    echo "scheduled: $N LaunchAgents already installed — this pack adds none; any skill proposing a schedule needs your own jobs review first"
    CONFLICTS=$((CONFLICTS+1))
  fi
else
  if crontab -l >/dev/null 2>&1; then
    N=$(crontab -l 2>/dev/null | grep -cv '^#')
    echo "scheduled: crontab already holds $N entries — this pack adds none; any skill proposing a schedule needs your own jobs review first"
    CONFLICTS=$((CONFLICTS+1))
  fi
fi
echo "preflight: $CONFLICTS existing-system item(s) found — all are reported, none are modified by this installer"
if [ "$PREFLIGHT_ONLY" = "1" ]; then exit 0; fi

# --- Plan ------------------------------------------------------------------
DISCOVERABLE=""; HELD_BACK=""
for d in "$SOURCE_DIR"/skills/*/; do
  name="$(basename "$d")"
  case "$MODE" in
    files-only) HELD_BACK="$HELD_BACK $name" ;;
    activate) DISCOVERABLE="$DISCOVERABLE $name" ;;
    discoverable)
      if in_list "$name" "$OPTIN_SKILLS"; then
        if in_list "$name" "$ACTIVATE_SPACED"; then
          DISCOVERABLE="$DISCOVERABLE $name"
        else
          HELD_BACK="$HELD_BACK $name"
        fi
      elif [ "$STRICT" = "1" ] && in_list "$name" "$REVIEW_SKILLS" \
           && ! in_list "$name" "$ACTIVATE_SPACED"; then
        HELD_BACK="$HELD_BACK $name"
      else
        DISCOVERABLE="$DISCOVERABLE $name"
      fi
      ;;
  esac
done

if [ "$MODE" = "activate" ] && [ -n "$OPTIN_SKILLS" ]; then
  echo "== Activating opt-in skills (state / schedule / spend / deploy / machine control) =="
  for n in $OPTIN_SKILLS; do echo "  opt-in: $n"; done
fi
if [ "$DRY_RUN" = "1" ]; then
  echo "dry run: discoverable:${DISCOVERABLE} | files-only:${HELD_BACK}"
  exit 0
fi

# --- Copy ------------------------------------------------------------------
mkdir -p "$WS/agents" "$WS/commands"
rsync -a "$SOURCE_DIR/agents/" "$WS/agents/"
rsync -a "$SOURCE_DIR/commands/" "$WS/commands/"
if [ -n "${DISCOVERABLE// }" ]; then
  mkdir -p "$WS/custom-skills"
  for n in $DISCOVERABLE; do rsync -a "$SOURCE_DIR/skills/$n/" "$WS/custom-skills/$n/"; done
fi
if [ -n "${HELD_BACK// }" ]; then
  mkdir -p "$WS/skills"
  for n in $HELD_BACK; do rsync -a "$SOURCE_DIR/skills/$n/" "$WS/skills/$n/"; done
fi

if [ ! -e "$WS/MUSE.md" ]; then
  cp "$SOURCE_DIR/MUSE.md" "$WS/MUSE.md"; echo "installed $WS/MUSE.md"
else
  echo "kept existing $WS/MUSE.md"
fi
for f in SOUL.md USER.md MEMORY.md AGENTS.md TOOLS.md IDENTITY.md; do
  if [ ! -e "$HOME/$f" ]; then
    cp "$SOURCE_DIR/templates/$f" "$HOME/$f"; echo "installed $HOME/$f"
  else
    echo "kept existing $HOME/$f"
  fi
done

# --- Discovery test ---------------------------------------------------------
DISC_OK=0; DISC_TOTAL=0
if [ -n "${DISCOVERABLE// }" ]; then
  for n in $DISCOVERABLE; do
    DISC_TOTAL=$((DISC_TOTAL+1))
    if [ -f "$WS/custom-skills/$n/SKILL.md" ] && [ -f "$WS/custom-skills/$n/skill.yaml" ]; then
      DISC_OK=$((DISC_OK+1))
    else
      echo "DISCOVERY FAIL: $n lacks SKILL.md or skill.yaml in $WS/custom-skills/$n" >&2
    fi
  done
  echo "discovery test: $DISC_OK/$DISC_TOTAL discoverable skills have SKILL.md + skill.yaml in $WS/custom-skills/"
  if [ "$DISC_OK" != "$DISC_TOTAL" ]; then
    echo "discovery test FAILED — installed files would not be found by Muse skill search" >&2
    exit 1
  fi
fi

# --- Summary: files vs tools vs activated -----------------------------------
N_SKILLS=$(ls "$SOURCE_DIR/skills" | wc -l | tr -d ' ')
N_AGENTS=$(ls "$SOURCE_DIR/agents" | wc -l | tr -d ' ')
N_COMMANDS=$(ls "$SOURCE_DIR/commands" | wc -l | tr -d ' ')
echo "== Summary =="
echo "files installed:       $N_SKILLS skills, $N_AGENTS agents, $N_COMMANDS commands (plus identity templates only where absent)"
echo "discoverable by Muse:  $DISC_OK skills in $WS/custom-skills/"
if [ -n "${HELD_BACK// }" ]; then
  echo "held back (files only, not discoverable):$HELD_BACK"
  echo "  activate any of them with: ./install.sh --activate <name>  (see MANIFEST.json for why each is gated)"
fi
echo "tools installed:       none — this installer copies files only; external tools a skill references are NOT installed (per-skill list: MANIFEST.json)"
echo "activated state:       none — no tracker, schedule, service, or account was created or modified"
echo "next steps:            install beads (this setup's tracker) + the core tools — see SETUP.md, or run: bash scripts/install-tools.sh"
