#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
TOOLS_JSON="${ADT_TOOLS_JSON:-$SCRIPT_DIR/tools.json}"
CACHE_DIR="${ADT_CACHE_DIR:-$HOME/.agentic-data-tools/cache}"
CLAUDE_SKILLS="${ADT_CLAUDE_SKILLS:-$HOME/.claude/skills}"
CODEX_SKILLS="${ADT_CODEX_SKILLS:-$HOME/.codex/skills}"
COPILOT_SKILLS="${ADT_COPILOT_SKILLS:-$HOME/.copilot/skills}"

PLATFORM=""
AGENT=""
PROJECT_DIR=""
DRY_RUN=false
STATUS=false
FORCE=false
UNPIN=false
PIN=""
YES=false
SELECTED_SKILLS=()

source "$SCRIPT_DIR/lib/ui.sh"
source "$SCRIPT_DIR/lib/core.sh"
source "$SCRIPT_DIR/lib/usage.sh"
source "$SCRIPT_DIR/lib/cmd_search.sh"
source "$SCRIPT_DIR/lib/cmd_list.sh"
source "$SCRIPT_DIR/lib/cmd_install.sh"
source "$SCRIPT_DIR/lib/cmd_uninstall.sh"
source "$SCRIPT_DIR/lib/cmd_update.sh"

COMMAND=""
SKILL_FILTER=""

while [[ $# -gt 0 ]]; do
    case $1 in
        search|list|install|uninstall|update)
            COMMAND="$1"; shift ;;
        -p|--platform)
            [ -z "${2-}" ] || [[ "${2}" == -* ]] && { err_msg "Flag --platform requires a value"; exit 2; }
            PLATFORM="$(printf '%s' "$2" | tr '[:upper:]' '[:lower:]')"; shift 2 ;;
        -a|--agent)
            [ -z "${2-}" ] || [[ "${2}" == -* ]] && { err_msg "Flag --agent requires a value"; exit 2; }
            AGENT="$(printf '%s' "$2" | tr '[:upper:]' '[:lower:]')"
            case "$AGENT" in
                claude|codex|copilot) ;;
                *) err_msg "Unknown agent '$AGENT' — valid values: claude, codex, copilot"; exit 1 ;;
            esac
            shift 2 ;;
        --project)
            [ -z "${2-}" ] || [[ "${2}" == -* ]] && { err_msg "Flag --project requires a value"; exit 2; }
            PROJECT_DIR="$(cd "$2" && pwd)"; shift 2 ;;
        -n|--dry-run)
            DRY_RUN=true; shift ;;
        -f|--force)
            FORCE=true; shift ;;
        --status)
            STATUS=true; shift ;;
        --unpin)
            UNPIN=true; shift ;;
        -y|--yes)
            YES=true; shift ;;
        --pin)
            [ -z "${2-}" ] || [[ "${2}" == -* ]] && { err_msg "Flag --pin requires a value"; exit 2; }
            PIN="$2"; shift 2 ;;
        -h|--help)
            case "$COMMAND" in
                search)    usage_search ;;
                list)      usage_list ;;
                install)   usage_install ;;
                uninstall) usage_uninstall ;;
                update)    usage_update ;;
                *)         usage ;;
            esac
            exit 0 ;;
        -*)
            err_msg "Unknown option: $1"; exit 1 ;;
        *)
            SKILL_FILTER="$1"; shift ;;
    esac
done

case "$COMMAND" in
    search)    cmd_search ;;
    list)      cmd_list ;;
    install)   cmd_install "$SKILL_FILTER" ;;
    uninstall) cmd_uninstall "$SKILL_FILTER" ;;
    update)    cmd_update ;;
    *)         usage; exit 1 ;;
esac
