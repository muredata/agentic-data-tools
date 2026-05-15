cmd_update() {
    validate_platform "$PLATFORM"
    if [ ! -d "$CACHE_DIR" ] || [ -z "$(ls -A "$CACHE_DIR" 2>/dev/null)" ]; then
        echo "Nothing cached yet. Run 'adt install' first."
        exit 0
    fi

    if [ "$STATUS" = true ]; then
        echo "Checking for updates..."
        local tool=""
        while IFS= read -r line; do
            if [[ "$line" == "---TOOL---" ]]; then
                local name cache_path
                name=$(field "$tool" "name")
                cache_path="$CACHE_DIR/$name"

                [ -d "$cache_path" ] || { tool=""; continue; }

                if ! git -C "$cache_path" symbolic-ref -q HEAD &>/dev/null; then
                    local pinned_hash
                    pinned_hash=$(git -C "$cache_path" rev-parse --short HEAD 2>/dev/null)
                    printf "\n%b%s — %bpinned @ %s%b\n" "$BOLD" "$name" "$YELLOW" "$pinned_hash" "$RESET"
                else
                    git -C "$cache_path" fetch --quiet 2>/dev/null
                    local local_ref remote_ref
                    local_ref=$(git -C "$cache_path" rev-parse HEAD)
                    remote_ref=$(git -C "$cache_path" rev-parse '@{u}' 2>/dev/null || echo "")
                    if [ -z "$remote_ref" ] || [ "$local_ref" = "$remote_ref" ]; then
                        printf "\n%b%s — %b✓ up to date%b\n" "$BOLD" "$name" "$GREEN" "$RESET"
                    else
                        printf "\n%b%s — %b↑ update available%b\n" "$BOLD" "$name" "$YELLOW" "$RESET"
                    fi
                fi

                while IFS= read -r path; do
                    local skills_dir="$cache_path/$path"
                    for skill_dir in "$skills_dir"*/; do
                        [ -d "$skill_dir" ] || continue
                        local skill_name skill_date
                        skill_name=$(basename "$skill_dir")
                        skill_date=$(git -C "$cache_path" log -1 --format="%ar" -- "${path}${skill_name}" 2>/dev/null || echo "unknown")
                        printf "  - %s %b(%s)%b\n" "$skill_name" "$BLUE" "$skill_date" "$RESET"
                    done
                done < <(get_paths "$tool")
                tool=""
            else
                tool+="$line"$'\n'
            fi
        done < <(iter_skills "$PLATFORM")
        echo ""
        echo "Run 'adt update' to pull latest."
        return
    fi

    echo "Updating cached repos..."
    echo ""

    for cache_path in "$CACHE_DIR"/*/; do
        [ -d "$cache_path" ] || continue
        local name
        name=$(basename "$cache_path")
        if ! git -C "$cache_path" symbolic-ref -q HEAD &>/dev/null; then
            if [ "$UNPIN" = false ]; then
                local pinned_hash
                pinned_hash=$(git -C "$cache_path" rev-parse --short HEAD 2>/dev/null)
                printf "%b○%b  %s (pinned @ %s — skipped)\n" "$YELLOW" "$RESET" "$name" "$pinned_hash"
                continue
            fi
            if [ "$DRY_RUN" = true ]; then
                dry_run_msg "Would unpin and update $name"
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
            dry_run_msg "Would update $name"
        else
            printf "↻  Updating %s...\n" "$name"
            git -C "$cache_path" pull --quiet
        fi
    done

    done_msg
}
