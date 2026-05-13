#!/usr/bin/env bash
# Quick web search in a floating terminal — Super+\

BOLD='\033[1m'
CYAN='\033[0;36m'
RESET='\033[0m'

clear
echo -e "${BOLD}${CYAN}  Quick Search${RESET}  (Ctrl+C or empty Enter to close)\n"
echo -n "  Search: "
read -r query
[[ -z "$query" ]] && exit 0

while [[ -n "$query" ]]; do
    echo ""
    ddgr -n 6 --np "$query"
    echo ""
    echo -e "${CYAN}  ──────────────────────────────────────${RESET}"
    echo -n "  New search (or Enter to close): "
    read -r query
done
