if [ -t 1 ]; then
    GREEN='\033[0;32m'; YELLOW='\033[0;33m'; BLUE='\033[0;34m'; BOLD='\033[1m'; RESET='\033[0m'
else
    GREEN=''; YELLOW=''; BLUE=''; BOLD=''; RESET=''
fi

dry_run_msg() { printf "%b[dry-run]%b %s\n" "$BLUE" "$RESET" "$1"; }
err_msg()     { printf "%b!%b %s\n" "$YELLOW" "$RESET" "$1"; }

done_msg() {
    [ "$OUTPUT" = json ] && return
    echo ""
    if [ "$DRY_RUN" = true ]; then
        echo "Run without --dry-run to apply changes."
    else
        echo "Done."
    fi
}

_json_str_arr() {
    printf '['
    local first=true
    for s in "$@"; do
        [ "$first" = true ] && first=false || printf ', '
        printf '"%s"' "$s"
    done
    printf ']'
}

_json_raw_arr() {
    printf '['
    local first=true
    for item in "$@"; do
        [ "$first" = true ] && first=false || printf ', '
        printf '%s' "$item"
    done
    printf ']'
}

json_envelope() {
    local cmd="$1"; shift
    local ts dry_run_field=""
    ts=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    case "$cmd" in
        install|uninstall|update)
            [ "$DRY_RUN" = true ] && dry_run_field='"dry_run":true,' || dry_run_field='"dry_run":false,'
            ;;
    esac
    printf '{"cmd":"%s","timestamp":"%s",%s"status":"success","data":%s}\n' \
        "$cmd" "$ts" "$dry_run_field" "$(_json_raw_arr "$@")" | jq .
}
