cmd_search() {
    validate_platform "$PLATFORM"
    mkdir -p "$CACHE_DIR"

    local json_items=()
    [ "$OUTPUT" != json ] && echo "Searching skills..."

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

            if [ "$OUTPUT" = json ]; then
                local agents=()
                while IFS= read -r ag; do agents+=("$ag"); done < <(get_agents "$tool")
                local agents_json skills_json
                agents_json=$(_json_str_arr "${agents[@]}")
                skills_json=$(_json_str_arr "${skills[@]}")
                json_items+=("{\"name\": \"$name\", \"platform\": \"$platform\", \"agents\": $agents_json, \"source\": \"$src\", \"skills\": $skills_json}")
            else
                printf "\n%b%s (%d)%b\n" "$BOLD" "$platform" "${#skills[@]}" "$RESET"
                for skill_name in "${skills[@]}"; do
                    printf "  - %s\n" "$skill_name"
                done
            fi
            tool=""
        else
            tool+="$line"$'\n'
        fi
    done < <(iter_skills "$PLATFORM")

    if [ "$OUTPUT" = json ]; then
        json_envelope "search" "${json_items[@]}"
    fi
}
