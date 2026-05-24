#!/usr/bin/env bash
os=$(grep '^NAME=' /etc/os-release | cut -d= -f2 | tr -d '"')
kernel=$(uname -r)
hl=$(hyprctl version 2>/dev/null | grep -oP '(?<=Hyprland )[0-9.]+' | head -1)
desktop="Hyprland ${hl:-?}"
cpu=$(lscpu | grep 'Model name' | sed 's/Model name:[ \t]*//' \
    | sed 's/Intel(R) Core(TM) //' | sed 's/ CPU.*//' | xargs)
cores=$(nproc)
gpu=$(lspci | grep -iP "vga|3d" | grep -v Intel | grep -oP '\[\K[^\]]+(?=\])' | head -1)
ram=$(free -h --si | awk '/Mem:/{print $2}')
uptime=$(uptime -p | sed 's/up //')
jq -n \
    --arg os      "$os"      \
    --arg kernel  "$kernel"  \
    --arg desktop "$desktop" \
    --arg cpu     "$cpu"     \
    --argjson cores "$cores" \
    --arg gpu     "${gpu:-N/A}" \
    --arg ram     "$ram"     \
    --arg uptime  "$uptime"  \
    '{os:$os,kernel:$kernel,desktop:$desktop,cpu:$cpu,cores:$cores,gpu:$gpu,ram:$ram,uptime:$uptime}'
