_select_skill_interactive() {
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

    local dirs=()
    if [ -n "$AGENT" ]; then
        case "$AGENT" in
            claude)   dirs=("$claude_target") ;;
            codex)    dirs=("$codex_target") ;;
            copilot)  dirs=("$copilot_target") ;;
        esac
    else
        dirs=("$claude_target" "$codex_target" "$copilot_target")
    fi

    local skills=()
    while IFS= read -r item; do
        skills+=("$item")
    done < <(for d in "${dirs[@]}"; do ls -1 "$d" 2>/dev/null; done | sort -u)

    if [ ${#skills[@]} -eq 0 ]; then
        echo "No skills installed."
        exit 0
    fi

    if ! command -v fzf &>/dev/null; then
        err_msg "Interactive selection requires fzf."
        printf "  Install: brew install fzf  /  apt install fzf  /  winget install fzf\n"
        exit 1
    fi

    local fzf_out
    fzf_out=$(printf '%s\n' "${skills[@]}" | fzf \
        --multi \
        --prompt="  > " \
        --header="Space/Tab: toggle  Enter: confirm  Esc: cancel" \
        --layout=reverse \
        --height=~60% \
        --marker=" ✓" \
        --pointer="▶" \
        --no-info 2>/dev/tty) || true
    [ -z "$fzf_out" ] && { SELECTED_SKILLS=(); return; }

    local selected=()
    while IFS= read -r line; do
        [ -n "$line" ] && selected+=("$line")
    done <<< "$fzf_out"

    local target_label
    [ -n "$AGENT" ] && target_label="$AGENT" || target_label="all agents"

    if [ ${#selected[@]} -eq 1 ]; then
        printf "\nUninstall %b%s%b from %s? [y/N] " "$BOLD" "${selected[0]}" "$RESET" "$target_label"
    else
        printf "\nUninstall the following from %s?\n" "$target_label"
        for s in "${selected[@]}"; do
            printf "  - %s\n" "$s"
        done
        printf "\n[y/N] "
    fi

    read -r confirm < /dev/tty
    case "$confirm" in
        y|Y) SELECTED_SKILLS=("${selected[@]}") ;;
        *)   SELECTED_SKILLS=() ;;
    esac
}

cmd_uninstall() {
    local skill_name="${1:-}"

    if [ -z "$skill_name" ]; then
        if [ ! -t 0 ]; then
            err_msg "Uninstall requires a skill name"; exit 2
        fi
        _select_skill_interactive
        [ ${#SELECTED_SKILLS[@]} -eq 0 ] && exit 0
    else
        SELECTED_SKILLS=("$skill_name")
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

    local targets=()
    if [ -n "$AGENT" ]; then
        case "$AGENT" in
            claude)   targets=("claude:$claude_target") ;;
            codex)    targets=("codex:$codex_target") ;;
            copilot)  targets=("copilot:$copilot_target") ;;
        esac
    else
        targets=("claude:$claude_target" "codex:$codex_target" "copilot:$copilot_target")
    fi

    local any_found=false
    for skill_name in "${SELECTED_SKILLS[@]}"; do
        echo ""
        echo "Uninstalling $skill_name..."
        echo ""

        local found=false
        for entry in "${targets[@]}"; do
            local agent_name="${entry%%:*}"
            local target_dir="${entry#*:}"
            local dest="$target_dir/$skill_name"
            [ -e "$dest" ] || [ -L "$dest" ] || continue
            found=true
            any_found=true
            if [ "$DRY_RUN" = true ]; then
                dry_run_msg "Would remove $skill_name[$agent_name]"
            elif [ -L "$dest" ]; then
                rm "$dest"
                printf "%b  %s[%s]\n" "${GREEN}✓${RESET}" "$skill_name" "$agent_name"
            else
                printf "%b  %s[%s] (not a symlink — remove manually: %s)\n" "${YELLOW}⚠${RESET}" "$skill_name" "$agent_name" "$dest"
            fi
        done

        if [ "$found" = false ]; then
            err_msg "Skill '$skill_name' is not installed."
        fi
    done

    if [ "$any_found" = false ]; then
        exit 1
    fi

    done_msg
}
