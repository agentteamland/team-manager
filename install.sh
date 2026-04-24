#!/usr/bin/env bash
# Bootstrap installer for the AgentTeamLand /team skill.
# Run once per machine to set up global infrastructure.
#
# Usage:
#   git clone https://github.com/agentteamland/team-manager.git ~/.claude/repos/agentteamland/team-manager
#   cd ~/.claude/repos/agentteamland/team-manager
#   ./install.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPOS_DIR="${HOME}/.claude/repos/agentteamland"
SKILL_TARGET="${HOME}/.claude/skills/team"

echo "🔧 AgentTeamLand — Bootstrap Installer"
echo "   Installs the globally-universal skills only."
echo "   Team-specific scaffolders (/create-new-project, /verify-system) come from teams you install."
echo ""

# Ensure directory structure
mkdir -p "${HOME}/.claude/skills"
mkdir -p "${HOME}/.claude/rules"
mkdir -p "${HOME}/.claude/agents"
mkdir -p "${REPOS_DIR}"

# 1. Install team skill (global)
if [ -L "${SKILL_TARGET}" ]; then
  rm "${SKILL_TARGET}"
elif [ -d "${SKILL_TARGET}" ]; then
  mv "${SKILL_TARGET}" "${SKILL_TARGET}.backup.$(date +%s)"
fi
ln -sf "${SCRIPT_DIR}/skill" "${SKILL_TARGET}"
echo "✅ /team skill installed globally"

# 2. Install core (global dependency)
CORE_DIR="${REPOS_DIR}/core"
if [ ! -d "${CORE_DIR}" ]; then
  echo "📦 Cloning core..."
  git clone https://github.com/agentteamland/core.git "${CORE_DIR}" 2>/dev/null
else
  echo "📦 Updating core..."
  cd "${CORE_DIR}" && git pull --quiet 2>/dev/null
fi

# Core symlinks (global) — all skills and rules
for d in "${CORE_DIR}/skills/"*/; do
  [ -d "$d" ] || continue
  ln -sf "${d%/}" "${HOME}/.claude/skills/$(basename "${d%/}")"
done
for f in "${CORE_DIR}/rules/"*.md; do
  [ -f "$f" ] || continue
  ln -sf "$f" "${HOME}/.claude/rules/$(basename "$f")"
done
echo "✅ Core installed globally (skills + rules)"

# 3. Install universal skills (brainstorm, rule)
# NOTE: create-project was retired in Karar #9 (2026-04-17) \u2014 scaffolders are
# now team-scoped. /create-new-project comes from the installed team
# (e.g. software-project-team), not as a global skill.
for skill_repo in brainstorm rule; do
  SKILL_REPO_DIR="${REPOS_DIR}/${skill_repo}"
  if [ ! -d "${SKILL_REPO_DIR}" ]; then
    echo "📦 Cloning ${skill_repo}..."
    git clone "https://github.com/agentteamland/${skill_repo}.git" "${SKILL_REPO_DIR}" 2>/dev/null
  else
    echo "📦 Updating ${skill_repo}..."
    cd "${SKILL_REPO_DIR}" && git pull --quiet 2>/dev/null
  fi

  # Symlink skills
  if [ -d "${SKILL_REPO_DIR}/skills" ]; then
    for d in "${SKILL_REPO_DIR}/skills/"*/; do
      [ -d "$d" ] || continue
      skill_name=$(basename "${d%/}")
      ln -sf "${d%/}" "${HOME}/.claude/skills/${skill_name}"
    done
  fi

  # Symlink rules
  if [ -d "${SKILL_REPO_DIR}/rules" ]; then
    for f in "${SKILL_REPO_DIR}/rules/"*.md; do
      [ -f "$f" ] || continue
      ln -sf "$f" "${HOME}/.claude/rules/$(basename "$f")"
    done
  fi
done
echo "✅ Universal skills installed (brainstorm, rule, rule-wizard)"

echo ""
echo "════════════════════════════════════════════"
echo "✅ Bootstrap complete!"
echo ""
echo "Global skills: /team, /save-learnings, /wiki, /create-code-diagram, /brainstorm, /rule, /rule-wizard"
echo "Global rules:  memory-system, agent-structure, version-check, brainstorm, karpathy-guidelines, learning-capture, docs-sync"
echo "Global agents: (none \u2014 agents are team-scoped, project-level)"
echo ""
echo "Repo cache:    ~/.claude/repos/agentteamland/"
echo ""
echo "Next steps (per project):"
echo "  cd your-project/"
echo "  /team install software-project-team     # or any team name from the registry"
echo "  /create-new-project YourProjectName     # team-scoped scaffolder"
echo "  /verify-system                          # team-scoped health check"
echo ""
echo "Browse teams: https://github.com/agentteamland/registry"
echo "════════════════════════════════════════════"
