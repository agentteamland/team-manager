---
name: team
description: "Manage agent teams: install (set up from git repo into PROJECT .claude/), list (show installed teams), remove (remove a team), update (update a team). Teams are project-level, not global."
argument-hint: "<install|list|remove|update> [repo-url or team-name]"
---

# /team Skill — Agent Team Manager

Installs, updates, and removes agent teams from git repos. Teams are installed **per-project** into the project's `.claude/` directory — NOT globally. This allows different projects to use different teams or different versions of the same team.

**What stays global:** Only core infrastructure (team skill itself, core rules, save-learnings). Everything else is project-level.

## Parameter Parsing

The first word determines the mode: `install`, `list`, `remove`, `update`.

---

## `install` Mode

**Usage:** `/team install <git-repo-url>`

**Flow:**

1. Get the repo URL (HTTPS or SSH)
2. Extract the team name from the repo name (last segment, `.git` removed)
3. Clone into `~/.claude/repos/agentteamland/{repo-name}/` directory (if already exists, run `git pull`)
4. Read `team.json` for version and dependencies:

```json
{
  "name": "software-project-team",
  "version": "1.0.0",
  "dependencies": [
    "https://github.com/agentteamland/core.git"
  ]
}
```

5. **Install dependencies first** — for each dependency URL, install it (recursive). Dependencies go to **global** `~/.claude/` (core is always global).

6. **Symlink into PROJECT's `.claude/`** (NOT global):

```bash
# Agents → project .claude/agents/
PROJECT_CLAUDE=".claude"  # relative to project root
mkdir -p "${PROJECT_CLAUDE}/agents" "${PROJECT_CLAUDE}/skills" "${PROJECT_CLAUDE}/rules"

TEAM_DIR="${HOME}/agent-teams/{team-name}"

# Agent symlinks (handle directory-based agents with agent.md + children/)
for agent_dir in "${TEAM_DIR}/agents/"*/; do
  if [ -d "$agent_dir" ] && [ -f "${agent_dir}/agent.md" ]; then
    agent_name=$(basename "$agent_dir")
    ln -sf "${agent_dir}/agent.md" "${PROJECT_CLAUDE}/agents/${agent_name}.md"
  fi
done

# Also handle flat agent .md files (if any)
for f in "${TEAM_DIR}/agents/"*.md; do
  [ -f "$f" ] && ln -sf "$f" "${PROJECT_CLAUDE}/agents/$(basename "$f")"
done

# Skills symlink
for d in "${TEAM_DIR}/skills/"*/; do
  [ -d "$d" ] && ln -sf "${d%/}" "${PROJECT_CLAUDE}/skills/$(basename "${d%/}")"
done

# Rules symlink
for f in "${TEAM_DIR}/rules/"*.md; do
  [ -f "$f" ] && ln -sf "$f" "${PROJECT_CLAUDE}/rules/$(basename "$f")"
done
```

7. **Save install manifest** at `.claude/.team-installs.json`:

```json
{
  "teams": [
    {
      "name": "software-project-team",
      "repo": "https://github.com/agentteamland/software-project-team.git",
      "version": "1.0.0",
      "installedAt": "2026-04-15T12:00:00Z",
      "sourceDir": "~/.claude/repos/agentteamland/software-project-team"
    }
  ]
}
```

8. Show summary to the user.

---

## `list` Mode

**Usage:** `/team list`

**Flow:**

1. Read `.claude/.team-installs.json` from the current project
2. For each installed team, count agents/skills/rules
3. Check version: compare installed version with `~/.claude/repos/agentteamland/{team}/team.json` version
4. Display:

```
Installed Teams (this project):
──────────────────────────────────────────────────────────
✅ software-project-team  v1.0.0  13 agents  3 skills  2 rules
──────────────────────────────────────────────────────────

Global (core):
✅ core                   v1.0.0  0 agents   1 skill   2 rules
```

---

## `remove` Mode

**Usage:** `/team remove <team-name>`

**Flow:**

1. Read `.claude/.team-installs.json`
2. Find the team entry
3. Remove all symlinks from `.claude/agents/`, `.claude/skills/`, `.claude/rules/` that point to that team's `~/.claude/repos/agentteamland/` directory
4. Remove the team entry from `.team-installs.json`
5. Ask: "Also delete source at ~/.claude/repos/agentteamland/{repo-name}/?" (usually No — other projects might use it)
6. Show summary

---

## `update` Mode

**Usage:** `/team update <team-name>`

**Flow:**

1. Navigate to `~/.claude/repos/agentteamland/{repo-name}/`
2. Run `git pull`
3. Read new version from `team.json`
4. Add symlinks for any newly added agents/skills/rules
5. Clean broken symlinks (deleted files)
6. Update version in `.claude/.team-installs.json`
7. Show summary with old → new version

---

## Version Auto-Check (Rule-Driven)

This skill does NOT handle auto-checking — that is handled by the `version-check` rule in core. The rule runs on every prompt and calls `git fetch` + version compare silently. If behind, it auto-pulls and refreshes symlinks.

See: `~/.claude/rules/version-check.md`

---

## Key Architecture Decisions

### Why Project-Level, Not Global?

- **Multiple projects, different teams.** Project A uses software-team, Project B uses youtube-team. Global would mix them.
- **Version independence.** Project A on v1.2, Project B on v1.3. Global forces same version.
- **Clean separation.** `ls .claude/agents/` shows exactly what THIS project uses.

### What Stays Global?

| Component | Location | Why Global |
|-----------|----------|-----------|
| `/team` skill | `~/.claude/skills/team/` | Must be available before any project is set up |
| `/save-learnings` | `~/.claude/skills/save-learnings/` | Universal across all projects |
| Core rules | `~/.claude/rules/memory-system.md`, `agent-structure.md`, `version-check.md` | Apply to every project |
| `/brainstorm` | `~/.claude/skills/brainstorm/` | Universal |
| `/rule` + `/rule-wizard` | `~/.claude/skills/rule/`, `rule-wizard/` | Universal |

### What Is Project-Level?

| Component | Location | Why Project |
|-----------|----------|------------|
| Team agents | `.claude/agents/` | Different per project |
| Team-specific skills | `.claude/skills/` | Different per project |
| Team-specific rules | `.claude/rules/` | Different per project |
| Coding standards | `.claude/docs/coding-standards/` | Different per project |

---

## Important Rules

1. **Teams install to `.claude/`, NOT `~/.claude/`.** Project-level, always.
2. **Dependencies (core) install to `~/.claude/`.** Global, always.
3. **Source repos live in `~/.claude/repos/agentteamland/`.** Shared across projects — only symlinks differ.
4. **Name conflict = warning.** Ask user, don't overwrite.
5. **Only symlinks are deleted on remove.** Source directory stays unless user confirms.
6. **`.team-installs.json` tracks what's installed.** Single source of truth for this project.
7. **Version auto-check is a separate rule.** Not part of this skill — handled by core.
