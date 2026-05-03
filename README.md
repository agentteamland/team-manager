# 🧩 AgentTeamLand Bootstrap

> Thin bootstrap that installs the `atl` CLI and primes the global cache. **The legacy `/team` skill that lived here was retired in `team-manager@2.0.0` (2026-05-02)** — every install / list / remove / update operation is now native in `atl`.

If you don't already have `atl` on your machine, run the bootstrap:

```bash
git clone https://github.com/agentteamland/team-manager.git ~/.claude/repos/agentteamland/team-manager
cd ~/.claude/repos/agentteamland/team-manager
./install.sh
```

The script is idempotent — safe to re-run. Once `atl` is installed (this script puts it on your PATH), this repo is no longer relevant; everything is driven by the CLI.

## 📚 Documentation

Full docs live at **[agentteamland.github.io/docs](https://agentteamland.github.io/docs/)**.

Most relevant sections:

- [Install the `atl` CLI](https://agentteamland.github.io/docs/guide/install) — the path to take if you already have `atl` and don't need this bootstrap
- [Quickstart](https://agentteamland.github.io/docs/guide/quickstart) — first install, first team, first session
- [`atl install`](https://agentteamland.github.io/docs/cli/install) — the command that replaces the retired `/team install` flow
- [`atl setup-hooks`](https://agentteamland.github.io/docs/cli/setup-hooks) — auto-update + learning-capture wiring (what `install.sh` opt-ins to)

## License

MIT. See [LICENSE](LICENSE).
