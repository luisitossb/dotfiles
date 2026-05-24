#!/usr/bin/env bash
g_in=$(hyprctl -j getoption general:gaps_in | \
    jq 'if .custom then (.custom | split(" ")[0] | tonumber) else .int end')
g_out=$(hyprctl -j getoption general:gaps_out | \
    jq 'if .custom then (.custom | split(" ")[0] | tonumber) else .int end')
border=$(hyprctl -j getoption general:border_size    | jq '.int')
rounding=$(hyprctl -j getoption decoration:rounding  | jq '.int')
blur=$(hyprctl -j getoption decoration:blur:enabled  | jq '.int == 1')
shadow=$(hyprctl -j getoption decoration:shadow:enabled | jq '.int == 1')
vrr=$(hyprctl -j getoption misc:vrr | jq '.int > 0')
jq -n \
    --argjson g_in    "$g_in"    \
    --argjson g_out   "$g_out"   \
    --argjson border  "$border"  \
    --argjson rounding "$rounding" \
    --argjson blur    "$blur"    \
    --argjson shadow  "$shadow"  \
    --argjson vrr     "$vrr"     \
    '{gaps_in:$g_in,gaps_out:$g_out,border:$border,rounding:$rounding,blur:$blur,shadow:$shadow,vrr:$vrr}'
