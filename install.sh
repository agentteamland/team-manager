#!/usr/bin/env bash
# Bootstrap installer for the AgentTeamLand global skills + rules + binary.
#
# v2.0.0 (2026-05-02): the legacy /team skill has been retired in favor of
# the `atl` CLI binary. This script now does the minimum needed to get a
# fresh machine ready: install atl (via brew if available) and prime the
# global cache by cloning the agentteamland/core repo.
#
# Per-project installs are driven by `atl install <team-name>` from inside
# the project directory — see https://agentteamland.github.io/docs/ for
# the full per-project flow.
#
# Usage:
#   git clone https://github.com/agentteamland/team-manager.git ~/.claude/repos/agentteamland/team-manager
#   cd ~/.claude/repos/agentteamland/team-manager
#   ./install.sh
#
# Re-running is safe (idempotent).

set -euo pipefail

REPOS_DIR="${HOME}/.claude/repos/agentteamland"

echo "🔧 AgentTeamLand — Bootstrap Installer (v2.0.0)"
echo ""

# ── Step 1: ensure atl is installed ─────────────────────────────────────
if command -v atl >/dev/null 2>&1; then
  echo "✅ atl already installed: $(atl --version 2>&1 | head -1)"
else
  echo "📦 atl not found on PATH."
  if command -v brew >/dev/null 2>&1; then
    echo "   Installing via Homebrew..."
    brew install agentteamland/tap/atl
    echo "✅ atl installed: $(atl --version 2>&1 | head -1)"
  else
    echo "   Homebrew is not available on this machine."
    echo "   Install atl manually from one of:"
    echo "     • brew install agentteamland/tap/atl  (macOS / Linuxbrew)"
    echo "     • scoop install atl                    (Windows; add bucket first)"
    echo "     • winget install AgentTeamLand.atl     (Windows)"
    echo "     • Or download a release from https://github.com/agentteamland/cli/releases"
    echo "   Then re-run this script."
    exit 1
  fi
fi

# ── Step 2: prime the global cache (clone core if missing) ─────────────
mkdir -p "${REPOS_DIR}"
CORE_DIR="${REPOS_DIR}/core"
if [ ! -d "${CORE_DIR}" ]; then
  echo "📦 Cloning core into the cache..."
  git clone --quiet https://github.com/agentteamland/core.git "${CORE_DIR}"
else
  echo "📦 core already cached at ${CORE_DIR}"
fi

# ── Step 3: register hooks (opt-in but recommended) ────────────────────
echo ""
echo "Registering Claude Code hooks (SessionStart + UserPromptSubmit)..."
echo "These keep the cache auto-updated and surface inline learning markers."
atl setup-hooks

# ── Done ───────────────────────────────────────────────────────────────
echo ""
echo "════════════════════════════════════════════════════════════════"
echo "✅ Bootstrap complete!"
echo ""
echo "Global cache: ${REPOS_DIR}"
echo ""
echo "Next steps (per project):"
echo "  cd your-project/"
echo "  atl install software-project-team     # or any team name from the registry"
echo "  atl install design-system-team        # for native design + prototype skills"
echo ""
echo "Browse teams:  https://github.com/agentteamland/registry"
echo "Full docs:     https://agentteamland.github.io/docs/"
echo "════════════════════════════════════════════════════════════════"
