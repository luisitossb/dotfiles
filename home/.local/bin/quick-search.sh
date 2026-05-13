#!/usr/bin/env bash
# Quick Google search in a floating terminal — Super+\

# colors
BOLD='\033[1m'
CYAN='\033[0;36m'
RESET='\033[0m'

clear
echo -e "${BOLD}${CYAN}  Quick Search${RESET}  (Ctrl+C to close)\n"
echo -n "  Search: "
read -r query
[[ -z "$query" ]] && exit 0

echo ""
googler --count 6 --noprompt "$query"

echo ""
echo -e "${CYAN}  ──────────────────────────────────────${RESET}"
echo -n "  New search (or Enter to close): "
read -r query2
[[ -z "$query2" ]] && exit 0

# loop for another search
while [[ -n "$query2" ]]; do
    echo ""
    googler --count 6 --noprompt "$query2"
    echo ""
    echo -e "${CYAN}  ──────────────────────────────────────${RESET}"
    echo -n "  New search (or Enter to close): "
    read -r query2
done
