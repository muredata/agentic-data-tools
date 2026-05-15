usage() {
    cat <<EOF
Install data platform skills from the command line.

Usage: $(basename "$0") <command> [-h]

Commands:
    install     Install skills
    list        Show installed skills
    search      Browse available skills
    uninstall   Remove an installed skill
    update      Pull latest for all cached repos

Flags:
    -h, --help    Show this help

Learn more:
    Run '$(basename "$0") <command> -h' for command-specific help.

EOF
}

usage_search() {
    cat <<EOF
Browse available skills from all configured platforms.

Usage: $(basename "$0") search [flags]

Flags:
    -o, --output <format>    Output format: plain (default), json
    -p, --platform <name>    Filter by platform (fabric, databricks)

Inherited flags:
    -h, --help               Show this help

EOF
}

usage_list() {
    cat <<EOF
Show installed skills for each agent.

Usage: $(basename "$0") list [flags]

Flags:
    -a, --agent <name>       Target agent only (claude, codex, copilot)
    -o, --output <format>    Output format: plain (default), json
        --project <path>     Target a project directory (not global)

Inherited flags:
    -h, --help               Show this help

EOF
}

usage_install() {
    cat <<EOF
Install all skills, platform skills, or a specific skill.

Usage: $(basename "$0") install [skill-name] [flags]

Flags:
    -a, --agent <name>       Target agent only (claude, codex, copilot)
    -n, --dry-run            Preview without making changes
    -f, --force              Reinstall even if already present
    -o, --output <format>    Output format: plain (default), json
        --pin <ref>          Pin to a specific git commit or tag
    -p, --platform <name>    Filter by platform (fabric, databricks)
        --project <path>     Target a project directory (not global)
    -y, --yes                Skip confirmation prompt

Inherited flags:
    -h, --help               Show this help

EOF
}

usage_uninstall() {
    cat <<EOF
Remove an installed skill.

Usage: $(basename "$0") uninstall <skill-name> [flags]

Flags:
    -a, --agent <name>       Target agent only (claude, codex, copilot)
    -n, --dry-run            Preview without making changes
    -o, --output <format>    Output format: plain (default), json
        --project <path>     Target a project directory (not global)

Inherited flags:
    -h, --help               Show this help

EOF
}

usage_update() {
    cat <<EOF
Pull latest changes for all cached repos.

Usage: $(basename "$0") update [flags]

Flags:
    -n, --dry-run            Preview without making changes
    -o, --output <format>    Output format: plain (default), json
        --status             Show update status and per-skill dates
        --unpin              Restore pinned repos to latest and update them

Inherited flags:
    -h, --help               Show this help

EOF
}
