# 🧩 AgentTeamLand Bootstrap

> **As of `team-manager@2.0.0` (2026-05-02), this repo is a thin bootstrap for the [`atl` CLI binary](https://github.com/agentteamland/cli).**
>
> The legacy `/team` skill that lived here has been retired — every install / list / remove / update operation is now native in `atl`. See the [migration note in skill/skill.md](skill/skill.md) for details.

## Quick Start

If you don't have `atl` yet, the bootstrap script installs it (via brew when available) and primes the global cache:

```bash
git clone https://github.com/agentteamland/team-manager.git ~/.claude/repos/agentteamland/team-manager
cd ~/.claude/repos/agentteamland/team-manager
./install.sh
```

The script is idempotent — safe to re-run.

If `atl` is already installed, you can skip this repo entirely. Use `atl` directly:

```bash
brew install agentteamland/tap/atl   # macOS / Linuxbrew
# or: scoop install atl              # Windows (after scoop bucket add)
# or: winget install AgentTeamLand.atl
```

## Per-project usage (atl)

```bash
cd your-project/

atl install software-project-team    # install a team from the public registry
atl install design-system-team       # native design + prototype skills
atl install <git-url>                # any team repo, by URL

atl list                             # list installed teams in this project
atl update                           # pull latest cache, refresh unmodified copies
atl remove <team>                    # remove a team (use --force for non-interactive)
atl --help                           # full reference
```

`atl install` copies the team's resources (agents, skills, rules) into `<project>/.claude/`. The global cache lives at `~/.claude/repos/agentteamland/{team}/` and is shared across all projects. Local edits in your project are protected — `atl update` only refreshes copies that haven't been touched.

## What this repo contains

| Path | Purpose |
|------|---------|
| `install.sh` | One-shot bootstrap: install atl + clone core into the cache + register Claude Code hooks |
| `skill/skill.md` | Deprecation stub of the retired `/team` skill — points readers to atl |
| `team.json` | Team manifest (declares the deprecation; for registry visibility) |

## What used to be here

Before `2.0.0`, this repo shipped:

- The `/team` skill (Markdown-driven Claude flow for install / list / remove / update)
- An install.sh that symlinked a long list of skills + rules into `~/.claude/`
- A 4-hook Claude Code setup (SessionStart + UserPromptSubmit + SessionEnd + PreCompact)

Both `/team` and the symlink topology were retired by `agentteamland/cli@v1.0.0` (project-local copies, install-mechanism-redesign decision). The 4-hook design was retired by `cli@v1.1.0` after the SessionEnd / PreCompact path was found never to deliver stdout to Claude.

The platform-wide review (2026-05-02) flagged keeping `/team` in production as a CRITICAL drift item — two competing implementations of the same flow, with subtly conflicting documentation, was actively confusing new contributors. This `2.0.0` release closes that gap.

## Where things live now

- The CLI binary: [agentteamland/cli](https://github.com/agentteamland/cli)
- Global skills (save-learnings, wiki, create-pr, create-code-diagram): [agentteamland/core](https://github.com/agentteamland/core)
- /brainstorm + /rule + /rule-wizard skills: [agentteamland/brainstorm](https://github.com/agentteamland/brainstorm), [agentteamland/rule](https://github.com/agentteamland/rule)
- Public team catalog: [agentteamland/registry](https://github.com/agentteamland/registry)
- Full docs: [agentteamland.github.io/docs](https://agentteamland.github.io/docs/)

## License

MIT. See [LICENSE](LICENSE).
