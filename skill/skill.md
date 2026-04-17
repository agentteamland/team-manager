---
name: team
description: "Manage AgentTeamLand teams: install (from registry name or git URL, with inheritance + override), list (show installed teams), remove, update. Teams are project-level."
argument-hint: "<install|list|remove|update> [team-name | git-url]"
---

# /team Skill — AgentTeamLand Team Manager

Installs, updates, and removes agent teams from the AgentTeamLand ecosystem. Teams are installed **per-project** into the project's `.claude/` directory — NOT globally. This lets different projects use different teams at different versions.

Key capabilities:

- **Registry name resolution** — `install <name>` looks up `agentteamland/registry/teams.json` and resolves to a git URL
- **Inheritance via `extends`** — a team can extend another; the parent's agents/skills/rules are inherited, the child can override by name or add new ones
- **`excludes` opt-out** — drop specific inherited names you don't want
- **Circular dependency detection** — installation stops with a clear error if a cycle is found
- **Unlimited inheritance depth** — A extends B extends C extends … is fine, as long as no cycle

**What stays global:** `/team` skill, `core` (save-learnings, memory-system rules, verify-system), brainstorm, rule, create-project. Everything else — team agents, team-specific skills/rules — is project-level.

## Parameter Parsing

The first word is the mode: `install`, `list`, `remove`, `update`. The remaining argument is either a **team name** (e.g. `software-project-team`) or a **git URL** (e.g. `https://github.com/agentteamland/software-project-team.git`).

---

## `install` Mode

**Usage:**

```
/team install software-project-team         # registry lookup (by name)
/team install https://github.com/X/Y.git    # direct URL
/team install agentteamland/X               # owner/name shorthand → https://github.com/agentteamland/X
```

### Flow

#### Step 1 — Resolve to a git URL

If the argument looks like a URL (starts with `https://`, `http://`, `git@`, or `ssh://`), skip to Step 2.

If the argument is `owner/name` (contains exactly one `/`), treat as `https://github.com/owner/name` and proceed.

Otherwise, treat as a team **name**:

1. Fetch the registry: `curl -sfL https://raw.githubusercontent.com/agentteamland/registry/main/teams.json` (with a 10s timeout)
2. Find the entry where `name === <arg>`
3. If found, use `entry.repo` as the git URL
4. If not found, error with:
   ```
   Team "<arg>" not found in the registry.
   Want to submit it? https://github.com/agentteamland/registry/blob/main/CONTRIBUTING.md
   Alternatively, install by URL: /team install https://github.com/owner/name
   ```
5. Show the status notice if the entry is `community`:
   ```
   ⚠ Note: "<arg>" is a community team (not reviewed by AgentTeamLand).
   ```

#### Step 2 — Install recursively with circular detection

Maintain a `visited` set (team name → install state) for the entire install session. This detects cycles across the whole dependency graph.

Recursive install function `install(gitUrl, versionConstraint=null)`:

1. Clone the repo into `~/.claude/repos/agentteamland/<repo-name>/` if missing, or `git pull` if present.
2. Read `team.json` at the repo root. Validate against the schema (fetch `team.schema.json` from `agentteamland/core` once per session and cache).
3. If `team.json.name` is already in `visited`:
   - If status is "installing" → **CIRCULAR DEPENDENCY**. Stop with error:
     ```
     Circular dependency detected: A → B → A
     ```
   - If status is "done" → skip (already installed in this session).
4. Mark `name` as `visited[name] = "installing"`.
5. If `team.json.extends` is not null:
   - Parse `"<parent-name>@<constraint>"` (e.g. `"software-project-team@^1.0.0"`)
   - Resolve parent-name → git URL (same as Step 1, first check registry, then assume it's the same-org if a short name)
   - Recursively `install(parent-url, parent-constraint)` → this will load parent into `visited` first
   - After parent install returns, the parent's effective agent/skill/rule set is merged into the "accumulator" for this install chain
6. Install this team's own agents/skills/rules (from `agents/`, `skills/`, `rules/` directories in the team repo).
7. For each inherited item from the parent that is also defined in this team's `team.json`: **child overrides** → the child's version wins. Same for `skills` and `rules`.
8. For each inherited item whose name appears in this team's `team.json.excludes`: **drop it** (do not symlink).
9. For each inherited+own remaining item: **merge into accumulator** keyed by `name`.
10. Check `dependencies` (other than the inheritance parent). Each listed dependency is installed *globally* (to `~/.claude/repos/agentteamland/`) but its agents/skills/rules are NOT symlinked into the project — `core` is the canonical example of a dependency, it provides global skills/rules only.
11. Mark `visited[name] = "done"`.
12. Only at the TOP of the call stack (the originally requested team): **materialize all symlinks** from the accumulator into `.claude/agents/`, `.claude/skills/`, `.claude/rules/`.

#### Step 3 — Symlink materialization (top-of-stack only)

```bash
PROJECT_CLAUDE=".claude"
mkdir -p "${PROJECT_CLAUDE}/agents" "${PROJECT_CLAUDE}/skills" "${PROJECT_CLAUDE}/rules"

# For each item in the accumulator (final effective set):
#   agent:  ln -sf "${teamDir}/agents/${name}/agent.md" "${PROJECT_CLAUDE}/agents/${name}.md"
#   skill:  ln -sf "${teamDir}/skills/${name}"        "${PROJECT_CLAUDE}/skills/${name}"
#   rule:   ln -sf "${teamDir}/rules/${name}.md"      "${PROJECT_CLAUDE}/rules/${name}.md"
```

Where `teamDir` is the cached `~/.claude/repos/agentteamland/<repo-name>` **of whichever team won the override chain** for that name. This is critical — the agent.md symlink must point to the repo that actually holds the winning version, not the top-of-stack child.

Before creating a new symlink, remove any existing same-named symlink first (no stale overwrite).

#### Step 4 — Write `.team-installs.json`

Record the top-level install plus the fully-resolved inheritance chain:

```json
{
  "teams": [
    {
      "name": "my-custom-team",
      "repo": "https://github.com/me/my-custom-team.git",
      "version": "0.1.0",
      "installedAt": "2026-04-17T14:00:00Z",
      "sourceDir": "~/.claude/repos/agentteamland/my-custom-team",
      "extendsChain": [
        "my-custom-team@0.1.0",
        "software-project-team@1.0.0"
      ],
      "effective": {
        "agents": ["api-agent", "socket-agent", "…", "my-custom-agent"],
        "skills": [],
        "rules": []
      }
    }
  ]
}
```

`extendsChain` = ordered list from child (index 0) to root ancestor (last index). `effective` = what actually ended up symlinked into the project (for fast diagnostic / `list` rendering).

#### Step 5 — Show summary

```
✅ Installed: my-custom-team@0.1.0
   Extends: software-project-team@^1.0.0
   Chain:   my-custom-team → software-project-team
   Effective: 14 agents (13 inherited + 1 own), 0 skills, 0 rules
   Excluded: ux-agent (from parent)
```

---

## `list` Mode

**Usage:** `/team list`

1. Read `.claude/.team-installs.json`
2. For each installed team, show: name, version, extends chain, effective counts, status (up-to-date / behind registry).
3. Pull registry `teams.json` and compare `version` vs `latestVersion` → flag outdated ones.

```
Installed Teams (this project):
──────────────────────────────────────────────────────────
✅ my-custom-team  v0.1.0  (extends software-project-team@^1.0.0)
   ├── 13 agents inherited, 1 own, 0 excluded → 14 effective
   └── skills: 0, rules: 0
   latest on registry: v0.1.0 (up to date)
──────────────────────────────────────────────────────────

Global (core):
✅ core                 v1.0.0  0 agents   4 skills  3 rules
```

---

## `remove` Mode

**Usage:** `/team remove <team-name>`

1. Read `.claude/.team-installs.json`
2. Find the team entry
3. Remove all symlinks from `.claude/agents/`, `.claude/skills/`, `.claude/rules/` that appear in the entry's `effective` map
4. Remove the entry from `.team-installs.json`
5. Ask the user: "Also delete source at `~/.claude/repos/agentteamland/<name>/`? (other projects may depend on it)"
6. Show summary

If the removed team was a **parent** of another installed team, warn:
```
⚠ my-custom-team extends <removed-team>. It may break on next update.
```

---

## `update` Mode

**Usage:** `/team update <team-name>` or `/team update` (all)

1. For each installed team:
   - `git pull` its source directory
   - Also pull its transitive parents (`extendsChain`)
   - Re-read `team.json`
   - Recompute the effective accumulator (override + excludes)
   - Refresh symlinks: remove broken, add new, update pointers for changed winners
2. Update `version` + `effective` in `.team-installs.json`
3. Show summary with old → new versions for every repo that changed

---

## Circular Dependency Detection

The `visited` map is the single source of truth:

- `visited[name] = undefined` → not seen yet
- `visited[name] = "installing"` → currently being resolved (seeing this again = CYCLE)
- `visited[name] = "done"` → already resolved in this session (reuse, no re-install)

Throw with an explicit chain in the error message:

```
Circular dependency detected:
  my-custom-team → parent-a → parent-b → my-custom-team

Fix: break the cycle by removing or relocating the 'extends' in one of the teams above.
```

There is **no depth limit** — any chain length is fine as long as it terminates.

---

## Registry Fetching

- The registry URL is hardcoded: `https://raw.githubusercontent.com/agentteamland/registry/main/teams.json`
- Fetch once per session, cache in memory
- 10-second timeout, no retry on failure — if the registry is unreachable, fall back to direct-URL install only
- Validate the fetched JSON against `registry.schema.json` (fetched once and cached) before trusting any entries

---

## Version Constraints

Constraints in `extends` and `dependencies` use npm-style:

- `^1.0.0` — compatible with 1.x.x, excluding 2.0.0 (caret, default for `extends`)
- `~1.2.0` — compatible with 1.2.x, excluding 1.3.0 (tilde)
- `>=1.0.0 <2.0.0` — range
- `1.0.0` — exact pin

When `git pull`ing, the resulting version is checked against the constraint. If it fails, **the install errors** — the user must either adjust the constraint or pin to a working version.

---

## Key Architecture

### Why Project-Level Teams?

- **Multiple projects, different teams.** Project A uses `software-project-team`, Project B uses `research-team`. Global install would mix them.
- **Version independence.** Project A at v1.2, Project B at v1.3 — global would force same version.
- **Clean separation.** `ls .claude/agents/` shows exactly what this project uses.

### What Stays Global?

| Component | Location | Reason |
|---|---|---|
| `/team` skill | `~/.claude/skills/team/` | Must exist before any project is set up |
| `/save-learnings` | `~/.claude/skills/save-learnings/` | Universal |
| Core rules | `~/.claude/rules/{memory-system,agent-structure,version-check}.md` | Apply to every project |
| `/brainstorm` | `~/.claude/skills/brainstorm/` | Universal |
| `/rule` + `/rule-wizard` | `~/.claude/skills/rule/`, `rule-wizard/` | Universal |
| `/create-new-project` | `~/.claude/skills/create-new-project/` | Universal scaffolder |
| `/verify-system` | `~/.claude/skills/verify-system/` | Universal health check |

### Source Repo Cache

All team source repos (both explicit installs and transitive parents) live in `~/.claude/repos/agentteamland/<repo-name>/`. Shared across projects — only the symlinks into each project's `.claude/` differ.

---

## Important Rules

1. **Teams install to `.claude/`, NOT `~/.claude/`.** Project-level, always.
2. **Source repos live in `~/.claude/repos/agentteamland/`.** Shared, cached.
3. **Dependencies (`core`, etc.) install globally** — their skills/rules go to `~/.claude/{skills,rules}/`, not the project.
4. **Schema validation is mandatory.** Every `team.json` is validated against the team schema on install. Malformed manifests are rejected.
5. **Circular detection is mandatory.** No install proceeds past a detected cycle.
6. **Child overrides parent by name.** Last one in the `extends` chain wins for any given agent/skill/rule name.
7. **`excludes` drops items outright.** They never get symlinked, not even from the child itself if listed there.
8. **Name conflict from two siblings** (same name in two `dependencies`, not via `extends`) is an error — only `extends` chain supports override, `dependencies` is flat.
9. **Only symlinks are deleted on remove.** Source directory stays unless the user confirms deletion.
10. **Version auto-check is handled by the `version-check` rule**, not this skill.

## See also

- [`agentteamland/registry`](https://github.com/agentteamland/registry) — the canonical list of installable teams
- [`agentteamland/core`](https://github.com/agentteamland/core) — the schema definitions (`schemas/team.schema.json`) and global rules
- [CONTRIBUTING to the registry](https://github.com/agentteamland/registry/blob/main/CONTRIBUTING.md) — how to submit your own team
