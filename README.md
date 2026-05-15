# agentic-data-tools

> This is experimental

A skills manager for external data tools. 

## Install

```bash
git clone https://github.com/muredata/agentic-data-tools
cd agentic-data-tools
ln -s "$PWD/adt.sh" ~/.local/bin/adt   # add adt to PATH
```

## Commands

```bash
adt <command> [-h]
```

| Command | Description |
|---|---|
| `install` | Install skills |
| `list` | Show installed skills |
| `search` | Browse available skills |
| `uninstall` | Remove an installed skill |
| `update` | Pull latest for all cached repos |

Run `adt <command> -h` for command-specific flags.

## Usage

```bash
# Browse available skills
adt search
adt search --platform fabric

# Show installed skills
adt list
adt list --agent claude
adt list --remote                        # check for updates + per-skill dates

# Install skills
adt install                              # all skills, all agents
adt install --platform fabric            # filter by platform
adt install databricks-core              # specific skill
adt install --agent claude               # claude only
adt install --project ~/code/my-project  # project scope, not global
adt install databricks-core --force      # reinstall if already present
adt install --dry-run                    # preview without changes

# Uninstall skills
adt uninstall                            # interactive picker (requires fzf)
adt uninstall databricks-core            # specific skill
adt uninstall databricks-core --agent claude
adt uninstall --dry-run

# Update cached repos
adt update
adt update --dry-run
```

Skills are cloned to `~/.agentic-data-tools/cache/` and symlinked into the appropriate agent directories (`~/.claude/skills/`, `~/.codex/skills/`).

## Index

See [docs/index.md](docs/index.md) for the full list of tools by platform.

## Contributing

To add a tool, open a PR updating `docs/index.md`. For issues or ideas, open an issue in this repository.

## License

The tool is available as open-source under the terms of the [MIT License](https://opensource.org/license/MIT).