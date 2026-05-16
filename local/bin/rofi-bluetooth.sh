#!/usr/bin/env bash
# Rofi-based Bluetooth manager using bluetoothctl.
set -euo pipefail

ROFI_CMD="rofi -dmenu -theme ~/.config/rofi/colors.rasi -font 'Fira Sans 11' -i"

# ── Helpers ────────────────────────────────────────────────────────────────

is_powered() { bluetoothctl show | grep -q "Powered: yes"; }

toggle_power() {
    if is_powered; then
        bluetoothctl power off
    else
        bluetoothctl power on
    fi
}

# ── Build menu ─────────────────────────────────────────────────────────────

powered=$(is_powered && echo "yes" || echo "no")
power_label=$([ "$powered" = "yes" ] && echo "󰂯  Disable Bluetooth" || echo "󰂯  Enable Bluetooth")

if [ "$powered" = "yes" ]; then
    # Get paired devices with their connection state
    devices=()
    while IFS= read -r line; do
        mac=$(echo "$line" | awk '{print $2}')
        name=$(bluetoothctl info "$mac" 2>/dev/null | awk '/Alias:/{$1=""; print substr($0,2)}')
        connected=$(bluetoothctl info "$mac" 2>/dev/null | grep -q "Connected: yes" && echo "  " || echo "   ")
        [ -n "$name" ] && devices+=("${connected}${name}  [${mac}]")
    done < <(bluetoothctl devices Paired 2>/dev/null)

    menu=$(printf '%s\n' "${devices[@]+"${devices[@]}"}" \
        "󰂰  Scan for devices" \
        "──────────────" \
        "$power_label")
else
    menu="$power_label"
fi

chosen=$(echo "$menu" | eval "$ROFI_CMD -p 'Bluetooth'") || exit 0

# ── Handle choice ──────────────────────────────────────────────────────────

case "$chosen" in
    *"Enable Bluetooth"*|*"Disable Bluetooth"*)
        toggle_power ;;
    *"Scan for devices"*)
        bluetoothctl scan on &
        sleep 5
        kill %1 2>/dev/null || true
        exec "$0" ;;
    *"──"*)
        exec "$0" ;;
    *)
        # Device line — extract MAC and toggle connection
        mac=$(echo "$chosen" | grep -oE '([0-9A-F]{2}:){5}[0-9A-F]{2}')
        [ -z "$mac" ] && exit 0
        if bluetoothctl info "$mac" | grep -q "Connected: yes"; then
            bluetoothctl disconnect "$mac"
        else
            bluetoothctl connect "$mac"
        fi ;;
esac
