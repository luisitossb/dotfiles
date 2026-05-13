#!/usr/bin/env bash
iface=$(ip route get 1.1.1.1 2>/dev/null | awk 'NR==1{for(i=1;i<=NF;i++) if($i=="dev"){print $(i+1); exit}}')
[[ -z "$iface" ]] && echo "↑ ? ↓ ?" && exit 0

get_bytes() {
    awk -v i="$1:" '$1==i {print $2, $10}' /proc/net/dev
}

read -r rx1 tx1 <<< "$(get_bytes "$iface")"
sleep 1
read -r rx2 tx2 <<< "$(get_bytes "$iface")"

fmt() {
    local b=$1
    if (( b >= 1048576 )); then
        awk "BEGIN {printf \"%.1fM\", $b/1048576}"
    elif (( b >= 1024 )); then
        awk "BEGIN {printf \"%dK\", $b/1024}"
    else
        echo "${b}B"
    fi
}

echo "↑$(fmt $((tx2-tx1))) ↓$(fmt $((rx2-rx1)))"
