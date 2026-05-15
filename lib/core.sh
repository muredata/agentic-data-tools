field() {
    printf '%s' "$1" | sed -n "s/.*\"$2\": *\"\([^\"]*\)\".*/\1/p" | head -1
}

get_agents() {
    printf '%s' "$1" | grep '"agents"' | sed 's/.*\[//;s/\].*//' | grep -oE '"[a-z]+"' | tr -d '"'
}

get_paths() {
    local block="$1"
    if printf '%s' "$block" | grep -q '"path": *\['; then
        printf '%s' "$block" | grep '"path"' | sed 's/.*"path": *\[//;s/\].*//' | grep -oE '"[^"]+"' | tr -d '"'
    else
        field "$block" "path"
    fi
}

iter_skills() {
    local pf="${1:-}" block="" depth=0 in_tools=0
    while IFS= read -r line; do
        [[ "$line" == *'"tools"'* ]] && in_tools=1
        [[ $in_tools -eq 0 ]] && continue

        local o c
        o=$(printf '%s' "$line" | tr -cd '{' | wc -c | tr -d ' ')
        c=$(printf '%s' "$line" | tr -cd '}' | wc -c | tr -d ' ')
        depth=$(( depth + o ))

        [[ $depth -ge 1 ]] && block+="$line"$'\n'

        depth=$(( depth - c ))

        if [[ $depth -lt 1 && -n "$block" ]]; then
            local type plat
            type=$(field "$block" "type")
            plat=$(field "$block" "platform")
            if [[ "$type" == "skill" && ( -z "$pf" || "$plat" == "$pf" ) ]]; then
                printf '%s' "$block"
                printf '%s\n' '---TOOL---'
            fi
            block=""
        fi
    done < "$TOOLS_JSON"
}

validate_platform() {
    local pf="$1"
    [ -z "$pf" ] && return 0
    grep -q "\"platform\": *\"${pf}\"" "$TOOLS_JSON" 2>/dev/null || {
        err_msg "Unknown platform '$pf' — check 'adt search' for valid platforms"; exit 1
    }
}

ensure_cached() {
    local name="$1" src="$2"
    local cache_path="$CACHE_DIR/$name"
    if [ ! -d "$cache_path" ]; then
        printf "\n↓  Cloning %s...\n" "$name" >&2
        git clone --quiet "$src" "$cache_path"
    elif [ "$(git -C "$cache_path" rev-parse --is-shallow-repository 2>/dev/null)" = "true" ]; then
        printf "\n↑  Unshallowing %s...\n" "$name" >&2
        git -C "$cache_path" fetch --unshallow --quiet
    fi
    echo "$cache_path"
}
