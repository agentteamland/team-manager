#!/usr/bin/env bash
# Bootstrap installer for Agent Team Manager skill.
# Run once per machine to enable the /team command globally.
#
# Usage:
#   git clone https://github.com/mkurak/agent-workshop-agent-team-manager-skill.git ~/agent-teams/manager
#   cd ~/agent-teams/manager
#   ./install.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_SOURCE="${SCRIPT_DIR}/skill"
SKILL_TARGET="${HOME}/.claude/skills/team"

# Ensure ~/.claude/skills exists
mkdir -p "${HOME}/.claude/skills"

# Ensure ~/agent-teams exists (default team storage)
mkdir -p "${HOME}/agent-teams"

# Create symlink
if [ -L "${SKILL_TARGET}" ]; then
  echo "⚠️  /team skill already installed (symlink exists). Updating..."
  rm "${SKILL_TARGET}"
elif [ -d "${SKILL_TARGET}" ]; then
  echo "⚠️  ${SKILL_TARGET} is a real directory. Backing up and replacing..."
  mv "${SKILL_TARGET}" "${SKILL_TARGET}.backup.$(date +%s)"
fi

ln -sf "${SKILL_SOURCE}" "${SKILL_TARGET}"

echo ""
echo "✅ /team skill installed globally!"
echo ""
echo "Usage:"
echo "  /team install <repo-url>     Install a team from a git repo"
echo "  /team list                   List installed teams"
echo "  /team remove <team-name>     Remove a team"
echo "  /team update <team-name>     Update a team (git pull + refresh symlinks)"
echo ""
echo "Teams will be stored in: ~/agent-teams/"
