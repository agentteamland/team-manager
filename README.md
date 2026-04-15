# 🧩 Agent Team Manager

A Claude Code skill for managing agent teams via Git repositories. Install, update, and remove entire teams of agents, skills, and rules with a single command.

## Quick Start

```bash
# One-time setup (bootstrap)
git clone https://github.com/mkurak/agent-workshop-agent-team-manager-skill.git ~/.claude/repos/mkurak/manager
cd ~/.claude/repos/mkurak/manager
./install.sh
```

That's it. The `/team` command is now available globally in every Claude Code session.

## Usage

```bash
# Install a team from any Git repo
/team install https://github.com/mkurak/agent-workshop-software-project-team.git

# List all installed teams
/team list

# Update a team (git pull + refresh symlinks)
/team update software-project-team

# Remove a team
/team remove software-project-team
```

## How It Works

Teams are Git repositories that follow a simple convention:

```
my-team/
├── agents/    → .md files symlinked to ~/.claude/agents/
├── skills/    → directories symlinked to ~/.claude/skills/
└── rules/     → .md files symlinked to ~/.claude/rules/
```

When you run `/team install <repo-url>`:
1. The repo is cloned to `~/.claude/repos/mkurak/<repo-name>/` (cached)
2. Agents, skills, and rules are symlinked to the **project's** `.claude/` directory
3. Everything becomes available in that specific project (not globally)

## Why Symlinks?

- **Single source of truth** — files live in the Git repo, not copied
- **Instant updates** — `git pull` in the team directory, changes are live
- **Clean removal** — `/team remove` deletes only symlinks, never source files
- **Shareable** — push your team to GitHub, anyone can install it

## Creating Your Own Team

1. Create a Git repo with `agents/`, `skills/`, and/or `rules/` directories
2. Add your `.md` files following Claude Code conventions
3. Push to GitHub
4. Install with `/team install <your-repo-url>`

See [agent-workshop-software-project-team](https://github.com/mkurak/agent-workshop-software-project-team) for a real-world example.

## License

MIT
