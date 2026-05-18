#!/usr/bin/env bash
iface=$(ip route get 1.1.1.1 2>/dev/null | awk 'NR==1{for(i=1;i<=NF;i++) if($i=="dev"){print $(i+1); exit}}')
[[ -z "$iface" ]] && echo "󰕒?.?? 󰇚?.?? MB/s" && exit 0

get_bytes() {
    awk -v i="$1:" '$1==i {print $2, $10}' /proc/net/dev
}

read -r rx1 tx1 <<< "$(get_bytes "$iface")"
sleep 1
read -r rx2 tx2 <<< "$(get_bytes "$iface")"

to_mbs() {
    awk "BEGIN {printf \"%.2f\", $1/1048576}"
}

echo "󰕒$(to_mbs $((tx2-tx1))) 󰇚$(to_mbs $((rx2-rx1))) MB/s"
