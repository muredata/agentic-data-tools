cmd_list() {
    if [ -n "$PROJECT_DIR" ]; then
        echo "Listing installed skills for project $PROJECT_DIR..."
    else
        echo "Listing installed skills globally..."
    fi

    local claude_target codex_target copilot_target
    if [ -n "$PROJECT_DIR" ]; then
        claude_target="$PROJECT_DIR/.claude/skills"
        codex_target="$PROJECT_DIR/.codex/skills"
        copilot_target="$PROJECT_DIR/.copilot/skills"
    else
        claude_target="$CLAUDE_SKILLS"
        codex_target="$CODEX_SKILLS"
        copilot_target="$COPILOT_SKILLS"
    fi

    local agents=()
    if [ -n "$AGENT" ]; then
        case "$AGENT" in
            claude)   agents=("claude:$claude_target") ;;
            codex)    agents=("codex:$codex_target") ;;
            copilot)  agents=("copilot:$copilot_target") ;;
        esac
    else
        agents=("claude:$claude_target" "codex:$codex_target" "copilot:$copilot_target")
    fi

    for entry in "${agents[@]}"; do
        local agent_name="${entry%%:*}"
        local skills_dir="${entry#*:}"
        local skills=()
        if [ -d "$skills_dir" ]; then
            while IFS= read -r item; do
                [ -n "$item" ] && skills+=("$item")
            done < <(ls -1 "$skills_dir" 2>/dev/null)
        fi
        printf "\n%b%s (%d)%b\n" "$BOLD" "$agent_name" "${#skills[@]}" "$RESET"
        for skill_name in "${skills[@]}"; do
            printf "  - %s\n" "$skill_name"
        done
    done
}
