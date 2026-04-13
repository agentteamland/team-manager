---
name: team
description: "Manage agent teams: install (set up from git repo), list (show installed teams), remove (remove a team), update (update a team)."
argument-hint: "<install|list|remove|update> [repo-url or team-name]"
---

# /team Skill — Agent Team Manager

Installs, updates, and removes agent teams from git repos. Each team can contain agents, skills, and rules. All are symlinked globally under `~/.claude/`.

## Parameter Parsing

The first word determines the mode: `install`, `list`, `remove`, `update`.

---

## `install` Mode

**Usage:** `/team install <git-repo-url>`

**Flow:**

1. Get the repo URL (HTTPS or SSH)
2. Extract the team name from the repo name (last segment, `.git` removed)
3. Clone into `~/agent-teams/{team-name}/` directory (if already exists, run `git pull`)
4. **Dependency check:** If a `team.json` file exists, read it. For each repo URL in the `dependencies` array, **install that dependency first** (recursive `/team install`). Skip if the dependency is already installed.

```json
// team.json example:
{
  "name": "software-project-team",
  "dependencies": [
    "https://github.com/mkurak/agent-workshop-core.git"
  ]
}
```

5. Scan the repo structure and create symlinks:

```bash
# Repo structure (convention):
{team-repo}/
├── agents/          → each .md file is symlinked to ~/.claude/agents/
├── skills/          → each subdirectory is symlinked to ~/.claude/skills/
└── rules/           → each .md file is symlinked to ~/.claude/rules/
```

5. Symlink creation rules:
   - `agents/*.md` → `~/.claude/agents/{file-name}.md` (flat symlink)
   - `skills/{skill-name}/` → `~/.claude/skills/{skill-name}/` (directory symlink)
   - `rules/*.md` → `~/.claude/rules/{file-name}.md` (flat symlink)
   - If there is a name conflict, **WARN and ASK** — do not overwrite the existing file

6. Create `~/agent-teams/{team-name}/.team-manifest.json`:
```json
{
  "name": "software-project-team",
  "repo": "https://github.com/mkurak/agent-workshop-software-project-team.git",
  "installedAt": "2026-04-13T00:30:00Z",
  "symlinks": [
    { "source": "agents/api-agent.md", "target": "~/.claude/agents/api-agent.md" },
    { "source": "rules/brainstorm.md", "target": "~/.claude/rules/brainstorm.md" }
  ]
}
```

7. Show summary to the user: how many agents, skills, rules were installed.

**Commands (to be run via Bash):**

```bash
# Clone
TEAM_DIR="${HOME}/agent-teams/{team-name}"
git clone {repo-url} "${TEAM_DIR}" 2>/dev/null || (cd "${TEAM_DIR}" && git pull)

# Agents symlink
for f in "${TEAM_DIR}/agents/"*.md; do
  [ -f "$f" ] && ln -sf "$f" "${HOME}/.claude/agents/$(basename "$f")"
done

# Skills symlink (directory-based)
for d in "${TEAM_DIR}/skills/"*/; do
  [ -d "$d" ] && ln -sf "$d" "${HOME}/.claude/skills/$(basename "$d")"
done

# Rules symlink
for f in "${TEAM_DIR}/rules/"*.md; do
  [ -f "$f" ] && ln -sf "$f" "${HOME}/.claude/rules/$(basename "$f")"
done
```

---

## `list` Mode

**Usage:** `/team list`

**Flow:**

1. Scan each subdirectory in `~/agent-teams/`
2. If `.team-manifest.json` exists in any of them, read it
3. If not, count from the directory structure (files under agents/, skills/, rules/)
4. Display in table format:

```
Installed Teams:
─────────────────────────────────────────────────────
✅ software-project-team    6 agents  3 skills  2 rules
✅ youtube-team             3 agents  1 skill   0 rules
─────────────────────────────────────────────────────
Total: 2 teams, 9 agents, 4 skills, 2 rules
```

---

## `remove` Mode

**Usage:** `/team remove <team-name>`

**Flow:**

1. Find the `~/agent-teams/{team-name}/` directory
2. If `.team-manifest.json` exists, read the symlink list from it
3. If not, scan the files under `agents/`, `skills/`, `rules/`
4. Remove each symlink from `~/.claude/` (only if it is a symlink — do not delete real files)
5. Ask the user: "Should I also delete the source directory? (~/agent-teams/{team-name}/)" — Yes/No
6. Show summary: how many symlinks were removed

**Commands:**

```bash
# Remove symlinks (only those that are symlinks)
for f in "${HOME}/.claude/agents/"*.md; do
  [ -L "$f" ] && readlink "$f" | grep -q "agent-teams/{team-name}" && rm "$f"
done

for d in "${HOME}/.claude/skills/"*/; do
  [ -L "${d%/}" ] && readlink "${d%/}" | grep -q "agent-teams/{team-name}" && rm "${d%/}"
done

for f in "${HOME}/.claude/rules/"*.md; do
  [ -L "$f" ] && readlink "$f" | grep -q "agent-teams/{team-name}" && rm "$f"
done
```

---

## `update` Mode

**Usage:** `/team update <team-name>`

**Flow:**

1. Navigate to the `~/agent-teams/{team-name}/` directory
2. Run `git pull`
3. Create symlinks for newly added files (existing ones are already up to date — the symlink points to the same file)
4. Clean up broken symlinks for deleted files
5. Show summary: updated, added, removed

**Commands:**

```bash
cd "${HOME}/agent-teams/{team-name}" && git pull

# Clean up broken symlinks
find "${HOME}/.claude/agents" -type l ! -exec test -e {} \; -delete 2>/dev/null
find "${HOME}/.claude/skills" -type l ! -exec test -e {} \; -delete 2>/dev/null
find "${HOME}/.claude/rules" -type l ! -exec test -e {} \; -delete 2>/dev/null

# Add symlinks for new files (existing ones are skipped)
for f in agents/*.md; do
  target="${HOME}/.claude/agents/$(basename "$f")"
  [ ! -e "$target" ] && ln -sf "$(pwd)/$f" "$target"
done
# ... same for skills and rules
```

---

## Important Rules

1. **Symlinks always go from `~/agent-teams/{name}/` to `~/.claude/`.** Not the other way around.
2. **Name conflict = warning.** The existing file is not overwritten. The user is asked.
3. **Only symlinks are deleted.** The `remove` command never deletes real files — only symlinks are removed.
4. **Manifest file is optional.** If it does not exist, all information can be derived from the directory structure. But if it exists, it is more reliable.
5. **Convention-over-configuration.** The directory names `agents/`, `skills/`, `rules/` in the repo are required. Other names are not recognized.
