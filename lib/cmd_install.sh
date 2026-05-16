_collect_skills() {
    local skill_filter="$1" claude_target="$2" codex_target="$3" copilot_target="$4"
    local tool=""
    while IFS= read -r line; do
        if [[ "$line" == "---TOOL---" ]]; then
            local name src platform cache_path
            name=$(field "$tool" "name")
            src=$(field "$tool" "source")
            platform=$(field "$tool" "platform")
            cache_path=$(ensure_cached "$name" "$src")

            local targets=()
            if [ -n "$AGENT" ]; then
                if get_agents "$tool" | grep -qx "$AGENT"; then
                    case "$AGENT" in
                        claude)   targets=("$claude_target") ;;
                        codex)    targets=("$codex_target") ;;
                        copilot)  targets=("$copilot_target") ;;
                    esac
                fi
            else
                while IFS= read -r agent; do
                    case "$agent" in
                        claude)   targets+=("$claude_target") ;;
                        codex)    targets+=("$codex_target") ;;
                        copilot)  targets+=("$copilot_target") ;;
                    esac
                done < <(get_agents "$tool")
            fi

            while IFS= read -r p; do
                local skills_dir="$cache_path/$p"
                [ -d "$skills_dir" ] || continue
                for skill_dir in "$skills_dir"*/; do
                    [ -d "$skill_dir" ] || continue
                    local skill_name
                    skill_name=$(basename "$skill_dir")
                    [ -n "$skill_filter" ] && [ "$skill_name" != "$skill_filter" ] && continue
                    local would_install=false
                    for target_dir in "${targets[@]}"; do
                        local dest="$target_dir/$skill_name"
                        if [ "$FORCE" = true ] || { [ ! -e "$dest" ] && [ ! -L "$dest" ]; }; then
                            would_install=true; break
                        fi
                    done
                    [ "$would_install" = true ] && printf '%s:%s\n' "$platform" "$skill_name"
                done
            done < <(get_paths "$tool")
            tool=""
        else
            tool+="$line"$'\n'
        fi
    done < <(iter_skills "$PLATFORM")
}

cmd_install() {
    local skill_filter="${1:-}"
    validate_platform "$PLATFORM"

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

    mkdir -p "$CACHE_DIR"

    if [ "$DRY_RUN" = false ] && [ "$YES" = false ] && [ "$FORCE" = false ] && [ "$OUTPUT" != json ] && [ -t 1 ]; then
        local preview_skills=()
        while IFS= read -r s; do
            preview_skills+=("$s")
        done < <(_collect_skills "$skill_filter" "$claude_target" "$codex_target" "$copilot_target")

        if [ ${#preview_skills[@]} -gt 0 ]; then
            printf "Install the following skills?\n"
            local cur_platform=""
            for s in "${preview_skills[@]}"; do
                local pf="${s%%:*}" sn="${s#*:}"
                if [ "$pf" != "$cur_platform" ]; then
                    printf "\n  %b%s%b\n" "$BOLD" "$pf" "$RESET"
                    cur_platform="$pf"
                fi
                printf "    - %s\n" "$sn"
            done
            printf "\n[y/N] "
            read -r confirm < /dev/tty
            printf "\n"
            case "$confirm" in
                y|Y) ;;
                *) echo "Aborted."; exit 0 ;;
            esac
        fi
    fi

    if [ "$OUTPUT" != json ]; then
        if [ -n "$PROJECT_DIR" ]; then
            echo "Installing skills for project $PROJECT_DIR..."
        else
            echo "Installing skills..."
        fi
    fi

    local json_items=()
    local tool=""
    while IFS= read -r line; do
        if [[ "$line" == "---TOOL---" ]]; then
            local name src cache_path
            name=$(field "$tool" "name")
            src=$(field "$tool" "source")

            cache_path=$(ensure_cached "$name" "$src")

            local all_paths=()
            while IFS= read -r p; do
                all_paths+=("$p")
            done < <(get_paths "$tool")

            local pin_hash=""
            if [ -n "$PIN" ] && [ "$DRY_RUN" = false ]; then
                local has_match=false
                for path in "${all_paths[@]}"; do
                    local skills_dir="$cache_path/$path"
                    for _sd in "$skills_dir"*/; do
                        [ -d "$_sd" ] || continue
                        local _sn
                        _sn=$(basename "$_sd")
                        if [ -z "$skill_filter" ] || [ "$_sn" = "$skill_filter" ]; then
                            has_match=true; break 2
                        fi
                    done
                done
                if [ "$has_match" = true ]; then
                    pin_hash=$(git -C "$cache_path" rev-parse --verify --short "$PIN" 2>/dev/null) || {
                        err_msg "Invalid pin ref '$PIN'"; exit 1
                    }
                    git -C "$cache_path" checkout --quiet --detach "$PIN"
                fi
            fi

            local targets=()
            if [ -n "$AGENT" ]; then
                if get_agents "$tool" | grep -qx "$AGENT"; then
                    case "$AGENT" in
                        claude)   targets=("claude:$claude_target") ;;
                        codex)    targets=("codex:$codex_target") ;;
                        copilot)  targets=("copilot:$copilot_target") ;;
                    esac
                fi
            else
                while IFS= read -r agent; do
                    case "$agent" in
                        claude)   targets+=("claude:$claude_target") ;;
                        codex)    targets+=("codex:$codex_target") ;;
                        copilot)  targets+=("copilot:$copilot_target") ;;
                    esac
                done < <(get_agents "$tool")
            fi

            local header_printed=false
            for path in "${all_paths[@]}"; do
                local skills_dir="$cache_path/$path"
                [ -d "$skills_dir" ] || continue
                for skill_dir in "$skills_dir"*/; do
                    [ -d "$skill_dir" ] || continue
                    local skill_name
                    skill_name=$(basename "$skill_dir")
                    [ -n "$skill_filter" ] && [ "$skill_name" != "$skill_filter" ] && continue

                    if [ "$OUTPUT" != json ] && [ "$header_printed" = false ]; then
                        printf "\nInstalling agent skills from %s\n\n" "$src"
                        header_printed=true
                    fi

                    for entry in "${targets[@]}"; do
                        local agent_name="${entry%%:*}"
                        local target_dir="${entry#*:}"
                        local dest="$target_dir/$skill_name"

                        if [ "$OUTPUT" = json ]; then
                            local result
                            if [ -n "$pin_hash" ]; then
                                result="pinned"
                                mkdir -p "$target_dir"
                                ln -sfn "$skill_dir" "$dest"
                            elif [ -e "$dest" ] || [ -L "$dest" ]; then
                                if [ "$FORCE" = true ]; then
                                    result="reinstalled"
                                    mkdir -p "$target_dir"
                                    ln -sfn "$skill_dir" "$dest"
                                else
                                    result="already_installed"
                                fi
                            else
                                result="installed"
                                [ "$DRY_RUN" = false ] && { mkdir -p "$target_dir"; ln -sfn "$skill_dir" "$dest"; }
                            fi
                            json_items+=("{\"skill\": \"$skill_name\", \"agent\": \"$agent_name\", \"result\": \"$result\"}")
                        else
                            if [ "$DRY_RUN" = true ]; then
                                dry_run_msg "Would link $skill_name[$agent_name] → $dest"
                            else
                                mkdir -p "$target_dir"
                                if [ -n "$pin_hash" ]; then
                                    ln -sfn "$skill_dir" "$dest"
                                    printf "%b  %s[%s] (pinned @ %s)\n" "${GREEN}✓${RESET}" "$skill_name" "$agent_name" "$pin_hash"
                                elif [ -e "$dest" ] || [ -L "$dest" ]; then
                                    if [ "$FORCE" = true ]; then
                                        ln -sfn "$skill_dir" "$dest"
                                        printf "%b  %s[%s] (reinstalled)\n" "${GREEN}✓${RESET}" "$skill_name" "$agent_name"
                                    else
                                        printf "%b  %s[%s] (already installed)\n" "${YELLOW}○${RESET}" "$skill_name" "$agent_name"
                                    fi
                                else
                                    ln -sfn "$skill_dir" "$dest"
                                    printf "%b  %s[%s]\n" "${GREEN}✓${RESET}" "$skill_name" "$agent_name"
                                fi
                            fi
                        fi
                    done
                done
            done
            tool=""
        else
            tool+="$line"$'\n'
        fi
    done < <(iter_skills "$PLATFORM")

    done_msg
    if [ "$OUTPUT" = json ]; then
        json_envelope "install" "${json_items[@]}"
    fi
}
