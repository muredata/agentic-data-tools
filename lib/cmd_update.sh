cmd_update() {
    validate_platform "$PLATFORM"
    if [ ! -d "$CACHE_DIR" ] || [ -z "$(ls -A "$CACHE_DIR" 2>/dev/null)" ]; then
        if [ "$OUTPUT" = json ]; then
            json_envelope "update"
        else
            echo "Nothing cached yet. Run 'adt install' first."
        fi
        exit 0
    fi

    if [ "$STATUS" = true ]; then
        [ "$OUTPUT" != json ] && echo "Checking for updates..."
        local json_items=()
        local tool=""
        while IFS= read -r line; do
            if [[ "$line" == "---TOOL---" ]]; then
                local name cache_path
                name=$(field "$tool" "name")
                cache_path="$CACHE_DIR/$name"

                [ -d "$cache_path" ] || { tool=""; continue; }

                local state pinned_hash=""
                if ! git -C "$cache_path" symbolic-ref -q HEAD &>/dev/null; then
                    pinned_hash=$(git -C "$cache_path" rev-parse --short HEAD 2>/dev/null)
                    state="pinned"
                else
                    git -C "$cache_path" fetch --quiet 2>/dev/null
                    local local_ref remote_ref
                    local_ref=$(git -C "$cache_path" rev-parse HEAD)
                    remote_ref=$(git -C "$cache_path" rev-parse '@{u}' 2>/dev/null || echo "")
                    if [ -z "$remote_ref" ] || [ "$local_ref" = "$remote_ref" ]; then
                        state="up_to_date"
                    else
                        state="update_available"
                    fi
                fi

                local skill_names=() skill_dates=()
                while IFS= read -r path; do
                    local skills_dir="$cache_path/$path"
                    for skill_dir in "$skills_dir"*/; do
                        [ -d "$skill_dir" ] || continue
                        local sn sd
                        sn=$(basename "$skill_dir")
                        sd=$(git -C "$cache_path" log -1 --format="%ar" -- "${path}${sn}" 2>/dev/null || echo "unknown")
                        skill_names+=("$sn")
                        skill_dates+=("$sd")
                    done
                done < <(get_paths "$tool")

                if [ "$OUTPUT" = json ]; then
                    local skill_items=()
                    for i in "${!skill_names[@]}"; do
                        skill_items+=("{\"name\": \"${skill_names[$i]}\", \"last_updated\": \"${skill_dates[$i]}\"}")
                    done
                    local skills_json
                    skills_json=$(_json_raw_arr "${skill_items[@]}")
                    if [ "$state" = pinned ]; then
                        json_items+=("{\"name\": \"$name\", \"state\": \"pinned\", \"pinned_hash\": \"$pinned_hash\", \"skills\": $skills_json}")
                    else
                        json_items+=("{\"name\": \"$name\", \"state\": \"$state\", \"pinned_hash\": null, \"skills\": $skills_json}")
                    fi
                else
                    if [ "$state" = pinned ]; then
                        printf "\n%b%s — %bpinned @ %s%b\n" "$BOLD" "$name" "$YELLOW" "$pinned_hash" "$RESET"
                    elif [ "$state" = up_to_date ]; then
                        printf "\n%b%s — %b✓ up to date%b\n" "$BOLD" "$name" "$GREEN" "$RESET"
                    else
                        printf "\n%b%s — %b↑ update available%b\n" "$BOLD" "$name" "$YELLOW" "$RESET"
                    fi
                    for i in "${!skill_names[@]}"; do
                        printf "  - %s %b(%s)%b\n" "${skill_names[$i]}" "$BLUE" "${skill_dates[$i]}" "$RESET"
                    done
                fi

                tool=""
            else
                tool+="$line"$'\n'
            fi
        done < <(iter_skills "$PLATFORM")

        if [ "$OUTPUT" = json ]; then
            json_envelope "update" "${json_items[@]}"
        else
            echo ""
            echo "Run 'adt update' to pull latest."
        fi
        return
    fi

    [ "$OUTPUT" != json ] && echo "Updating cached repos..."
    [ "$OUTPUT" != json ] && echo ""

    local json_items=()
    for cache_path in "$CACHE_DIR"/*/; do
        [ -d "$cache_path" ] || continue
        local name
        name=$(basename "$cache_path")
        if ! git -C "$cache_path" symbolic-ref -q HEAD &>/dev/null; then
            if [ "$UNPIN" = false ]; then
                local pinned_hash
                pinned_hash=$(git -C "$cache_path" rev-parse --short HEAD 2>/dev/null)
                [ "$OUTPUT" != json ] && printf "%b○%b  %s (pinned @ %s — skipped)\n" "$YELLOW" "$RESET" "$name" "$pinned_hash"
                json_items+=("{\"name\": \"$name\", \"result\": \"pinned_skipped\"}")
                continue
            fi
            if [ "$DRY_RUN" = true ]; then
                [ "$OUTPUT" != json ] && dry_run_msg "Would unpin and update $name"
                json_items+=("{\"name\": \"$name\", \"result\": \"unpinned_updated\"}")
                continue
            fi
            local branch
            branch=$(git -C "$cache_path" symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||')
            if [ -z "$branch" ]; then
                branch=$(git -C "$cache_path" branch -r 2>/dev/null | grep -E 'origin/(main|master)' | head -1 | sed 's|.*origin/||' | tr -d ' ')
            fi
            [ -z "$branch" ] && branch="main"
            git -C "$cache_path" checkout --quiet "$branch"
        fi
        if [ "$DRY_RUN" = true ]; then
            [ "$OUTPUT" != json ] && dry_run_msg "Would update $name"
            json_items+=("{\"name\": \"$name\", \"result\": \"updated\"}")
        else
            [ "$OUTPUT" != json ] && printf "↻  Updating %s...\n" "$name"
            git -C "$cache_path" pull --quiet
            json_items+=("{\"name\": \"$name\", \"result\": \"updated\"}")
        fi
    done

    done_msg
    if [ "$OUTPUT" = json ]; then
        json_envelope "update" "${json_items[@]}"
    fi
}
