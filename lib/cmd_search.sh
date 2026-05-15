cmd_search() {
    validate_platform "$PLATFORM"
    mkdir -p "$CACHE_DIR"
    echo "Searching skills..."
    local tool=""
    while IFS= read -r line; do
        if [[ "$line" == "---TOOL---" ]]; then
            local name src platform cache_path
            name=$(field "$tool" "name")
            src=$(field "$tool" "source")
            platform=$(field "$tool" "platform")

            cache_path=$(ensure_cached "$name" "$src")

            local skills=()
            while IFS= read -r path; do
                local skills_dir="$cache_path/$path"
                for skill_dir in "$skills_dir"*/; do
                    [ -d "$skill_dir" ] || continue
                    skills+=("$(basename "$skill_dir")")
                done
            done < <(get_paths "$tool")

            printf "\n%b%s (%d)%b\n" "$BOLD" "$platform" "${#skills[@]}" "$RESET"
            for skill_name in "${skills[@]}"; do
                printf "  - %s\n" "$skill_name"
            done
            tool=""
        else
            tool+="$line"$'\n'
        fi
    done < <(iter_skills "$PLATFORM")
}
