#!/usr/bin/env bash
# Bootstrap installer for Agent Team Manager skill.
# Run once per machine to set up the global infrastructure.
#
# Usage:
#   git clone https://github.com/mkurak/agent-workshop-agent-team-manager-skill.git ~/.claude/repos/mkurak/agent-workshop-agent-team-manager-skill
#   cd ~/.claude/repos/mkurak/agent-workshop-agent-team-manager-skill
#   ./install.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPOS_DIR="${HOME}/.claude/repos/mkurak"
SKILL_TARGET="${HOME}/.claude/skills/team"

echo "🔧 Agent Workshop — Bootstrap Installer"
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
CORE_DIR="${REPOS_DIR}/agent-workshop-core"
if [ ! -d "${CORE_DIR}" ]; then
  echo "📦 Cloning core..."
  git clone https://github.com/mkurak/agent-workshop-core.git "${CORE_DIR}" 2>/dev/null
else
  echo "📦 Updating core..."
  cd "${CORE_DIR}" && git pull --quiet 2>/dev/null
fi

# Core symlinks (global)
ln -sf "${CORE_DIR}/skills/save-learnings" "${HOME}/.claude/skills/save-learnings"
ln -sf "${CORE_DIR}/rules/memory-system.md" "${HOME}/.claude/rules/memory-system.md"
ln -sf "${CORE_DIR}/rules/agent-structure.md" "${HOME}/.claude/rules/agent-structure.md"
ln -sf "${CORE_DIR}/rules/version-check.md" "${HOME}/.claude/rules/version-check.md"
echo "✅ Core installed globally (save-learnings + rules)"

# 3. Install universal skills (brainstorm, rule, rule-wizard, create-new-project)
for skill_repo in agent-workshop-brainstorm-skill agent-workshop-rule-skill agent-workshop-create-project-skill; do
  SKILL_REPO_DIR="${REPOS_DIR}/${skill_repo}"
  if [ ! -d "${SKILL_REPO_DIR}" ]; then
    echo "📦 Cloning ${skill_repo}..."
    git clone "https://github.com/mkurak/${skill_repo}.git" "${SKILL_REPO_DIR}" 2>/dev/null
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
echo "✅ Universal skills installed (brainstorm, rule, rule-wizard, create-new-project)"

echo ""
echo "════════════════════════════════════════════"
echo "✅ Bootstrap complete!"
echo ""
echo "Global skills: /team, /save-learnings, /brainstorm, /rule, /rule-wizard, /create-new-project"
echo "Global rules:  memory-system, agent-structure, version-check, brainstorm"
echo "Global agents: (none — agents are project-level)"
echo ""
echo "Repo cache:    ~/.claude/repos/mkurak/"
echo ""
echo "Next steps:"
echo "  cd your-project/"
echo "  /team install https://github.com/mkurak/agent-workshop-software-project-team.git"
echo "  /create-new-project YourProjectName"
echo "════════════════════════════════════════════"
