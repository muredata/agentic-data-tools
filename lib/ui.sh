if [ -t 1 ]; then
    GREEN='\033[0;32m'; YELLOW='\033[0;33m'; BLUE='\033[0;34m'; BOLD='\033[1m'; RESET='\033[0m'
else
    GREEN=''; YELLOW=''; BLUE=''; BOLD=''; RESET=''
fi

dry_run_msg() { printf "%b[dry-run]%b %s\n" "$BLUE" "$RESET" "$1"; }
err_msg()     { printf "%b!%b %s\n" "$YELLOW" "$RESET" "$1"; }

done_msg() {
    echo ""
    if [ "$DRY_RUN" = true ]; then
        echo "Run without --dry-run to apply changes."
    else
        echo "Done."
    fi
}
