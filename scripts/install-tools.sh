#!/usr/bin/env bash
# Install the tool belt the starter's skills assume: beads (bd) plus the
# core tools from SETUP.md. Dry-run by default — it prints the commands
# it would run; pass --yes to actually install. Per-skill extras are NOT
# installed here; see MANIFEST.json (tools_referenced) per skill.
set -euo pipefail

YES=0
[ "${1:-}" = "--yes" ] && YES=1

CMDS=()
if [ "$(uname -s)" = "Darwin" ]; then
  command -v brew >/dev/null 2>&1 || {
    echo "Homebrew not found. Install it first: https://brew.sh" >&2; exit 1; }
  CMDS+=(
    "brew install git node python jq gh ffmpeg rclone"
    "brew install beads"
    "brew install stripe/stripe-cli/stripe"
    "npm install -g wrangler"
  )
else
  CMDS+=(
    "sudo apt-get update && sudo apt-get install -y git curl python3 jq ffmpeg rclone"
    "curl -fsSL https://raw.githubusercontent.com/steveyegge/beads/main/scripts/install.sh | bash"
    "npm install -g wrangler"
  )
  echo "note: node, gh, and the stripe CLI have distro-specific installs — see SETUP.md" >&2
fi

echo "Commands:"
printf '  %s\n' "${CMDS[@]}"
if [ "$YES" != "1" ]; then
  echo "dry run only — re-run with --yes to install"
  exit 0
fi
for c in "${CMDS[@]}"; do
  echo "+ $c"
  bash -c "$c"
done
echo "done. Next: cd your-project && bd init"
