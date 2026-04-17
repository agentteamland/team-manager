# 🧩 Agent Team Manager

A Claude Code skill for managing agent teams via Git repositories. Install, update, and remove entire teams of agents, skills, and rules with a single command.

## Quick Start

```bash
# One-time setup (bootstrap)
git clone https://github.com/agentteamland/team-manager.git ~/.claude/repos/agentteamland/team-manager
cd ~/.claude/repos/agentteamland/team-manager
./install.sh
```

This installs:
- `/team` skill (global)
- Core infrastructure (memory system, version check, agent structure rules)
- Universal skills (`/brainstorm`, `/rule`, `/rule-wizard`, `/save-learnings`, `/create-new-project`)

## Usage

```bash
# Install a team into your project
/team install https://github.com/agentteamland/software-project-team.git

# List installed teams (for current project)
/team list

# Update a team (git pull + refresh symlinks)
/team update software-project-team

# Remove a team from project
/team remove software-project-team
```

## Architecture

```
~/.claude/
├── repos/agentteamland/              ← All repos cached here (single source of truth)
│   ├── core/
│   ├── software-project-team/
│   └── ...
├── skills/                    ← ONLY global skills (team, brainstorm, rule, etc.)
├── rules/                     ← ONLY global rules (memory-system, version-check, etc.)
└── agents/                    ← EMPTY (agents are project-level, never global)

your-project/.claude/
├── agents/                    ← Team agents symlinked here (per-project)
│   ├── api-agent.md → ~/.claude/repos/agentteamland/.../agents/api-agent/agent.md
│   └── ...
├── skills/                    ← Team skills symlinked here (if any)
└── rules/                     ← Team rules symlinked here (if any)
```

## How It Works

Teams are Git repositories that follow a simple convention:

```
my-team/
├── agents/    → symlinked to PROJECT's .claude/agents/
├── skills/    → symlinked to PROJECT's .claude/skills/
├── rules/     → symlinked to PROJECT's .claude/rules/
└── team.json  → name, version, dependencies
```

When you run `/team install <repo-url>`:
1. Repo is cloned to `~/.claude/repos/agentteamland/<repo-name>/` (cached once, shared across projects)
2. Agents, skills, and rules are symlinked into the **project's** `.claude/` directory
3. Everything becomes available in **that specific project** only

### Why Project-Level?

- **Multiple projects, different teams.** Project A uses software-team, Project B uses youtube-team.
- **Version independence.** Project A on v1.2, Project B on v1.3.
- **Clean separation.** `ls .claude/agents/` shows exactly what THIS project uses.

### Automatic Version Check

On every prompt, the system automatically checks if cached repos are outdated. If a newer version exists on origin, it auto-pulls silently — no user interaction needed. You always work with the latest version.

## Creating Your Own Team

1. Create a Git repo with `agents/`, `skills/`, and/or `rules/` directories
2. Add a `team.json` with name, version, and dependencies
3. Add your agent `.md` files following the [agent structure conventions](https://github.com/agentteamland/core)
4. Push to GitHub
5. Install with `/team install <your-repo-url>`

See [software-project-team](https://github.com/agentteamland/software-project-team) for a real-world example with 13 agents.

## License

MIT
