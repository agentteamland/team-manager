---
name: team
description: "DEPRECATED — use the atl CLI binary instead. Run atl install <team>, atl list, atl remove <team>, or atl update. The /team skill is kept here only as a stub that points users to atl."
argument-hint: "(deprecated — see atl --help)"
---

# /team Skill — DEPRECATED

> **This skill has been retired as of `team-manager@2.0.0` (2026-05-02).**
>
> All functionality moved to the `atl` CLI binary in `agentteamland/cli@v1.0.0` (2026-05-02). The CLI is faster, has better error messages, supports the project-local copy install topology that the v1.0.0 install-mechanism-redesign decision required, and is the single source of truth for team install / list / remove / update.

## Why retired

Two competing implementations of the same flow (a Markdown skill that drove Claude through bash steps + a binary that did it natively) created persistent user confusion:

- The skill described **symlink-to-cache** install topology, which `atl v1.0.0` retired in favor of project-local copies.
- Documentation drifted: workspace state snapshot pointed at `atl install`, this skill's README pointed at `/team install`. New users could not tell which was authoritative.
- Auto-update via `atl session-start` is binary-only — the skill could not participate.

The platform-wide review (2026-05-02) identified this as a CRITICAL drift item. The decision was to retire the skill and concentrate on `atl`.

## What to use instead

| What you used to do | What to do now |
|---|---|
| `/team install <name>` | `atl install <name>` |
| `/team install <git-url>` | `atl install <git-url>` |
| `/team list` | `atl list` |
| `/team remove <name>` | `atl remove <name>` (use `--force` for non-interactive) |
| `/team update` | `atl update` (or let the SessionStart hook auto-run) |

The atl binary is installed via `brew install agentteamland/tap/atl` (macOS / Linuxbrew), `scoop install atl` (Windows), or `winget install AgentTeamLand.atl`.

If `atl` is not yet on your machine, the bootstrap script in this repo will install it (and prime the global cache) for you:

```bash
git clone https://github.com/agentteamland/team-manager.git ~/.claude/repos/agentteamland/team-manager
cd ~/.claude/repos/agentteamland/team-manager
./install.sh
```

## Removing this skill from existing installs

If you previously installed `team-manager@<2.0.0`, the old `/team` skill symlink may still exist under `~/.claude/skills/team`. It is safe to remove:

```bash
rm -rf ~/.claude/skills/team
```

The `install.sh` in `team-manager@2.0.0+` no longer creates the symlink in the first place.

## History

- `team-manager@1.x` (2026-04-17 → 2026-05-01): symlink-based install topology, /team skill drove Claude through clone + symlink + manifest steps via bash.
- `team-manager@2.0.0` (2026-05-02): skill retired; install.sh reduced to atl + cache-prime bootstrap. Companion to `agentteamland/cli@v1.0.0` install-mechanism-redesign and the platform-wide review's C-1 finding.
