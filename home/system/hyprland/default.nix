# So best window tiling manager
{ pkgs, config, inputs, lib, ... }:
let
  border-size = config.var.theme.border-size;
  gaps-in = config.var.theme.gaps-in;
  gaps-out = config.var.theme.gaps-out;
  active-opacity = config.var.theme.active-opacity;
  inactive-opacity = config.var.theme.inactive-opacity;
  rounding = config.var.theme.rounding;
  blur = config.var.theme.blur;
  keyboardLayout = config.var.keyboardLayout;
  thirdpartyRoot = inputs.thirdparty-nixos-configuration;
  quickshellDir = pkgs.runCommand "quickshell-thirdparty" { nativeBuildInputs = [ pkgs.python3 ]; } ''
    mkdir -p "$out"
    cp -r ${thirdpartyRoot}/config/sessions/hyprland/scripts/quickshell/. "$out/"
    chmod -R u+w "$out"
    sed -i 's|$(dirname "$0")/.env|$HOME/.config/hypr/qs-weather.env|g' "$out/calendar/weather.sh"
    sed -i 's|echo ".env file not found!"|:|g' "$out/calendar/weather.sh"
    sed -i '/exit 1/d' "$out/calendar/weather.sh"
    sed -i 's|~/.config/hypr/scripts/quickshell/calendar/weather.sh|bash ~/.config/hypr/scripts/quickshell/calendar/weather.sh|g' "$out/TopBar.qml"
    sed -i '/Quickshell System Tray/,/System Pills Wrapper/{/System Pills Wrapper/!d}' "$out/TopBar.qml"
    sed -i 's|~/.config/hypr/scripts/quickshell/workspaces.sh > /tmp/qs_workspaces.json|~/.config/hypr/scripts/quickshell/workspaces.sh /tmp/qs_workspaces.json|g' "$out/TopBar.qml"
    sed -i 's|tail -n 1 /tmp/qs_workspaces.json 2>/dev/null|cat /tmp/qs_workspaces.json 2>/dev/null|g' "$out/TopBar.qml"
    sed -i 's|~/.config/hypr/scripts/rofi_show.sh drun|menu|g' "$out/TopBar.qml"
    sed -i 's|Quickshell.execDetached\\(\\[\"pavucontrol\"\\]\\)|Quickshell.execDetached([\"pavucontrol\"])|g' "$out/TopBar.qml"
    sed -i 's|margins { top: 8; bottom: 0; left: 4; right: 4 }|margins { top: 20; bottom: 0; left: 20; right: 20 }|g' "$out/TopBar.qml"
    # Robust WiFi/Bluetooth status without DBus failures
    cat > "$out/sys_info.sh" <<'SH'
#!/usr/bin/env bash

IW="${pkgs.iw}/bin/iw"
HCICONFIG="${pkgs.bluez}/bin/hciconfig"
HCITOOL="${pkgs.bluez}/bin/hcitool"

wifi_iface() {
    $IW dev 2>/dev/null | awk '/Interface/ {print $2; exit}'
}

wifi_connected() {
    local iface
    iface=$(wifi_iface)
    [ -z "$iface" ] && return 1
    $IW dev "$iface" link 2>/dev/null | grep -q "Connected to"
}

## WIFI
get_wifi_status() {
    local nmcli_out
    nmcli_out=$(nmcli -t -f WIFI g 2>/dev/null) || nmcli_out=""
    if [ -n "$nmcli_out" ]; then
        if [ "$nmcli_out" = "disabled" ] && wifi_connected; then
            echo "enabled"
        else
            echo "$nmcli_out"
        fi
        return
    fi

    # Fallback without DBus
    local iface
    iface=$(wifi_iface)
    if [ -z "$iface" ]; then
        echo "disabled"
        return
    fi
    if wifi_connected; then
        echo "enabled"
        return
    fi
    if [ -f "/sys/class/net/$iface/operstate" ] && grep -qi "up" "/sys/class/net/$iface/operstate"; then
        echo "enabled"
    else
        echo "disabled"
    fi
}

get_wifi_ssid() {
    local ssid
    ssid=$(nmcli -t -f ACTIVE,SSID dev wifi 2>/dev/null | grep '^yes' | cut -d: -f2)
    if [ -n "$ssid" ]; then
        echo "$ssid"
        return
    fi

    # Fallback without DBus
    local iface
    iface=$(wifi_iface)
    [ -z "$iface" ] && { echo ""; return; }
    ssid=$($IW dev "$iface" link 2>/dev/null | awk -F': ' '/SSID:/ {print $2; exit}')
    if [ -n "$ssid" ]; then
        echo "$ssid"
    else
        echo ""
    fi
}

get_kb_layout() {
    # Get active keyboard layout from Hyprland
    # Requires jq installed
    local layout=$(hyprctl devices -j | jq -r '.keyboards[] | select(.main == true) | .active_keymap' | head -n1)
    
    # Shorten the name (e.g., "English (US)" -> "US", "Spanish" -> "ES")
    # You might need to adjust the cut logic depending on your specific layout names
    echo "$layout" | cut -c1-2 | tr '[:lower:]' '[:upper:]'
}

get_wifi_icon() {
    local status=$(get_wifi_status)
    local ssid=$(get_wifi_ssid)
    
    if [ "$status" = "enabled" ]; then
        if [ -n "$ssid" ]; then
            # Get signal strength for better icon
            local signal=$(get_wifi_strength)
            if [ "$signal" -ge 75 ]; then
                echo "󰤨"
            elif [ "$signal" -ge 50 ]; then
                echo "󰤥"
            elif [ "$signal" -ge 25 ]; then
                echo "󰤢"
            else
                echo "󰤟"
            fi
        else
            echo "󰤯"  # WiFi on but not connected
        fi
    else
        echo "󰤮"  # WiFi off
    fi
}

get_wifi_strength() {
    local signal
    signal=$(nmcli -f IN-USE,SIGNAL dev wifi 2>/dev/null | grep '^\*' | awk '{print $2}')
    if [ -n "$signal" ]; then
        echo "$signal"
        return
    fi

    # Fallback without DBus
    local iface sig pct
    iface=$(wifi_iface)
    [ -z "$iface" ] && { echo "0"; return; }
    sig=$($IW dev "$iface" link 2>/dev/null | awk '/signal:/ {print $2; exit}')
    if [ -n "$sig" ]; then
        pct=$(( (sig + 100) * 2 ))
        [ "$pct" -lt 0 ] && pct=0
        [ "$pct" -gt 100 ] && pct=100
        echo "$pct"
    else
        echo "0"
    fi
}

toggle_wifi() {
    if [ "$(nmcli -t -f WIFI g 2>/dev/null)" = "enabled" ]; then
        nmcli radio wifi off
        notify-send -u low -i network-wireless-disabled "WiFi" "Disabled"
    else
        nmcli radio wifi on
        notify-send -u low -i network-wireless-enabled "WiFi" "Enabled"
    fi
}

## BLUETOOTH
get_bt_status() {
    if $HCITOOL con 2>/dev/null | awk '/< LE|ACL/ {print $3; exit}' | grep -q ':'; then
        echo "on"
        return
    fi
    if $HCICONFIG 2>/dev/null | grep -q "UP RUNNING"; then
        echo "on"
    else
        echo "off"
    fi
}

get_bt_icon() {
    local status=$(get_bt_status)
    
    if [ "$status" = "on" ]; then
        if $HCITOOL con 2>/dev/null | awk '/< LE|ACL/ {print $3; exit}' | grep -q ':'; then
            echo "󰂱"  # Connected
        else
            echo "󰂯"  # On but not connected
        fi
    else
        echo "󰂲"  # Off
    fi
}

get_bt_connected_device() {
    if [ "$(get_bt_status)" = "on" ]; then
        local mac name
        mac=$($HCITOOL con 2>/dev/null | awk '/< LE|ACL/ {print $3; exit}')
        if [ -n "$mac" ]; then
            name=$(timeout 2s bluetoothctl info "$mac" 2>/dev/null | awk -F': ' '/Name:/ {print $2; exit}')
            [ -z "$name" ] && name=$($HCITOOL name "$mac" 2>/dev/null)
            if [ -n "$name" ]; then
                echo "$name"
            else
                echo "$mac"
            fi
        else
            echo "Disconnected"
        fi
    else
        echo "Off"
    fi
}

toggle_bt() {
    local status=$(get_bt_status)
    
    if [ "$status" = "on" ]; then
        bluetoothctl power off 2>/dev/null
        notify-send -u low -i bluetooth-disabled "Bluetooth" "Disabled"
    else
        bluetoothctl power on 2>/dev/null
        notify-send -u low -i bluetooth-active "Bluetooth" "Enabled"
    fi
}

## BRIGHTNESS
get_brightness() {
    if command -v brightnessctl &> /dev/null; then
        local percent
        percent=$(brightnessctl -m 2>/dev/null | cut -d, -f4 | tr -d '%')
        if [ -n "$percent" ]; then
            echo "$percent"
        else
            echo "50"
        fi
    elif command -v light &> /dev/null; then
        local percent
        percent=$(light -G 2>/dev/null | cut -d. -f1)
        if [ -n "$percent" ]; then
            echo "$percent"
        else
            echo "50"
        fi
    elif [ -f /sys/class/backlight/*/brightness ]; then
        local current max
        current=$(cat /sys/class/backlight/*/brightness 2>/dev/null | head -n1)
        max=$(cat /sys/class/backlight/*/max_brightness 2>/dev/null | head -n1)
        if [ -n "$current" ] && [ -n "$max" ] && [ "$max" -gt 0 ]; then
            echo $(( current * 100 / max ))
        else
            echo "50"
        fi
    else
        echo "50"
    fi
}

## AUDIO
get_volume() {
    if command -v pamixer &> /dev/null; then
        pamixer --get-volume 2>/dev/null || echo "50"
    elif command -v pactl &> /dev/null; then
        pactl get-sink-volume @DEFAULT_SINK@ 2>/dev/null | grep -oP '\d+%' | head -n1 | tr -d '%' || echo "50"
    else
        echo "50"
    fi
}

is_muted() {
    if command -v pamixer &> /dev/null; then
        if pamixer --get-mute 2>/dev/null | grep -q "true"; then
            echo "true"
        else
            echo "false"
        fi
    elif command -v pactl &> /dev/null; then
        if pactl get-sink-mute @DEFAULT_SINK@ 2>/dev/null | grep -q "yes"; then
            echo "true"
        else
            echo "false"
        fi
    else
        echo "false"
    fi
}

toggle_mute() {
    if command -v pamixer &> /dev/null; then
        pamixer --toggle-mute 2>/dev/null
        if [ "$(is_muted)" = "true" ]; then
            notify-send -u low -i audio-volume-muted "Volume" "Muted"
        else
            notify-send -u low -i audio-volume-high "Volume" "Unmuted ($(get_volume)%)"
        fi
    elif command -v pactl &> /dev/null; then
        pactl set-sink-mute @DEFAULT_SINK@ toggle 2>/dev/null
        if [ "$(is_muted)" = "true" ]; then
            notify-send -u low -i audio-volume-muted "Volume" "Muted"
        else
            notify-send -u low -i audio-volume-high "Volume" "Unmuted ($(get_volume)%)"
        fi
    fi
}

get_volume_icon() {
    local vol muted

    # Get volume and strip non-numeric characters
    vol=$(get_volume | tr -cd '0-9')
    muted=$(is_muted)

    # Default to 0 if volume is empty
    [ -z "$vol" ] && vol=0

    if [ "$muted" = "true" ]; then
        echo "󰝟"  # Muted
    elif [ "$vol" -ge 70 ]; then
        echo "󰕾"  # High
    elif [ "$vol" -ge 30 ]; then
        echo "󰖀"  # Medium
    elif [ "$vol" -gt 0 ]; then
        echo "󰕿"  # Low
    else
        echo "󰝟"  # Zero/Muted
    fi
}

## BATTERY
get_battery_percent() {
    if [ -f /sys/class/power_supply/BAT*/capacity ]; then
        local percent
        percent=$(cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -n1)
        if [ -n "$percent" ]; then
            echo "$percent"
        else
            echo "100"
        fi
    else
        echo "100"
    fi
}

get_battery_status() {
    if [ -f /sys/class/power_supply/BAT*/status ]; then
        cat /sys/class/power_supply/BAT*/status 2>/dev/null | head -n1
    else
        echo "Full"
    fi
}

get_battery_icon() {
    local percent status
    percent=$(get_battery_percent)
    status=$(get_battery_status)
    
    # Show charging icons when charging or full
    if [ "$status" = "Charging" ] || [ "$status" = "Full" ]; then
        if [ "$percent" -ge 90 ]; then
            echo "󰂅"  # Charging full
        elif [ "$percent" -ge 80 ]; then
            echo "󰂋"  # Charging 80
        elif [ "$percent" -ge 60 ]; then
            echo "󰂊"  # Charging 60
        elif [ "$percent" -ge 40 ]; then
            echo "󰢞"  # Charging 40
        elif [ "$percent" -ge 20 ]; then
            echo "󰂆"  # Charging 20
        else
            echo "󰢜"  # Charging low
        fi
    else
        # Discharging icons
        if [ "$percent" -ge 90 ]; then
            echo "󰁹"  # 100%
        elif [ "$percent" -ge 80 ]; then
            echo "󰂂"  # 90%
        elif [ "$percent" -ge 70 ]; then
            echo "󰂁"  # 80%
        elif [ "$percent" -ge 60 ]; then
            echo "󰂀"  # 70%
        elif [ "$percent" -ge 50 ]; then
            echo "󰁿"  # 60%
        elif [ "$percent" -ge 40 ]; then
            echo "󰁾"  # 50%
        elif [ "$percent" -ge 30 ]; then
            echo "󰁽"  # 40%
        elif [ "$percent" -ge 20 ]; then
            echo "󰁼"  # 30%
        elif [ "$percent" -ge 10 ]; then
            echo "󰁻"  # 20%
        else
            echo "󰁺"  # 10% or less
        fi
    fi
}

## SYSTEM
get_cpu_usage() {
    if command -v top &> /dev/null; then
        top -bn1 2>/dev/null | grep "Cpu(s)" | awk '{print int($2 + $4)}' || echo "0"
    else
        echo "0"
    fi
}

get_memory_usage() {
    if command -v free &> /dev/null; then
        free 2>/dev/null | grep Mem | awk '{print int($3/$2 * 100)}' || echo "0"
    else
        echo "0"
    fi
}

get_uptime() {
    if command -v uptime &> /dev/null; then
        uptime -p 2>/dev/null | sed 's/up //' || echo "unknown"
    else
        echo "unknown"
    fi
}

## EXECUTION
cmd="$1"
case $cmd in
    --wifi-status) get_wifi_status ;;
    --wifi-ssid) get_wifi_ssid ;;
    --wifi-icon) get_wifi_icon ;;
    --wifi-strength) get_wifi_strength ;;
    --wifi-toggle) toggle_wifi ;;
    
    --bt-status) get_bt_status ;;
    --bt-icon) get_bt_icon ;;
    --bt-connected) get_bt_connected_device ;;
    --bt-toggle) toggle_bt ;;
    
    --brightness) get_brightness ;;
    
    --volume) get_volume ;;
    --volume-icon) get_volume_icon ;;
    --is-muted) is_muted ;;
    --toggle-mute) toggle_mute ;;
    
    --battery-percent) get_battery_percent ;;
    --battery-status) get_battery_status ;;
    --battery-icon) get_battery_icon ;;
    
    --cpu-usage) get_cpu_usage ;;
    --memory-usage) get_memory_usage ;;
    --uptime) get_uptime ;;

    --kb-layout) get_kb_layout ;;
    
    *) echo "Unknown command: $cmd" ;;
esac
SH
    # Ensure sys_info and network scripts can find nmcli/bluetoothctl
    sed -i 's|\\<nmcli\\>|${pkgs.networkmanager}/bin/nmcli|g' "$out/sys_info.sh"
    sed -i 's|\\<bluetoothctl\\>|${pkgs.bluez}/bin/bluetoothctl|g' "$out/sys_info.sh"
    sed -i 's|\\<nmcli\\>|${pkgs.networkmanager}/bin/nmcli|g' "$out/network/wifi_panel_logic.sh"
    sed -i 's|\\<bluetoothctl\\>|${pkgs.bluez}/bin/bluetoothctl|g' "$out/network/bluetooth_panel_logic.sh"
    # Override wifi panel logic to tolerate nmcli DBus failures
    cat > "$out/network/wifi_panel_logic.sh" <<'SH'
#!/usr/bin/env bash

IW="${pkgs.iw}/bin/iw"

get_iface() {
    $IW dev 2>/dev/null | awk '/Interface/ {print $2; exit}'
}

wifi_connected() {
    local iface
    iface=$(get_iface)
    [ -z "$iface" ] && return 1
    $IW dev "$iface" link 2>/dev/null | grep -q "Connected to"
}

# Check if WiFi is enabled
POWER=$(nmcli radio wifi 2>/dev/null || echo "unknown")

if [[ "$POWER" == "disabled" ]]; then
    if wifi_connected; then
        POWER="enabled"
    else
        echo '{ "power": "off", "connected": null, "networks": [] }'
        exit 0
    fi
fi

# Function to get icon based on signal strength
get_icon() {
    local signal=$1
    if [[ $signal -ge 80 ]]; then echo "󰤨";
    elif [[ $signal -ge 60 ]]; then echo "󰤥";
    elif [[ $signal -ge 40 ]]; then echo "󰤢";
    elif [[ $signal -ge 20 ]]; then echo "󰤟";
    else echo "󰤯"; fi
}

CACHE_DIR="/tmp/quickshell_network_cache"
mkdir -p "$CACHE_DIR"

CONNECTED_JSON="null"

# Get current connection details (nmcli preferred, iw fallback)
CURRENT_RAW=$(nmcli -t -f active,ssid,signal,security device wifi 2>/dev/null | grep "^yes")
if [[ -n "$CURRENT_RAW" ]]; then
    IFS=':' read -r active ssid signal security <<< "$CURRENT_RAW"
    icon=$(get_icon "$signal")

    SAFE_SSID="''${ssid//[^a-zA-Z0-9]/_}"
    CACHE_FILE="$CACHE_DIR/wifi_$SAFE_SSID"

    if [ -f "$CACHE_FILE" ]; then
        source "$CACHE_FILE"
    fi

    if [ -z "$IP" ] || [ "$IP" == "No IP" ] || [ -z "$FREQ" ]; then
        IFACE=$(nmcli -t -f DEVICE,TYPE d 2>/dev/null | awk -F: '$2=="wifi"{print $1;exit}')
        IP=$(ip -4 addr show dev "$IFACE" 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -n1)
        [ -z "$IP" ] && IP="No IP"

        FREQ=$($IW dev "$IFACE" link 2>/dev/null | grep freq | awk '{print $2}')
        [ -n "$FREQ" ] && FREQ="''${FREQ} MHz" || FREQ="Unknown"

        echo "IP=\"$IP\"" > "$CACHE_FILE"
        echo "FREQ=\"$FREQ\"" >> "$CACHE_FILE"
    fi

    CONNECTED_JSON=$(jq -n \
                  --arg id "$ssid" \
                  --arg ssid "$ssid" \
                  --arg icon "$icon" \
                  --arg signal "$signal" \
                  --arg security "$security" \
                  --arg ip "$IP" \
                  --arg freq "$FREQ" \
                  '{id: $id, ssid: $ssid, icon: $icon, signal: $signal, security: $security, ip: $ip, freq: $freq}')
else
    # iw fallback for connected info
    IFACE=$(get_iface)
    if [ -n "$IFACE" ] && wifi_connected; then
        SSID=$($IW dev "$IFACE" link 2>/dev/null | awk -F': ' '/SSID:/ {print $2; exit}')
        SIGNAL=$($IW dev "$IFACE" link 2>/dev/null | awk '/signal:/ {print $2; exit}')
        [ -n "$SIGNAL" ] || SIGNAL="0"
        ICON=$(get_icon "$SIGNAL")
        IP=$(ip -4 addr show dev "$IFACE" 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -n1)
        [ -z "$IP" ] && IP="No IP"
        FREQ=$($IW dev "$IFACE" link 2>/dev/null | grep freq | awk '{print $2}')
        [ -n "$FREQ" ] && FREQ="''${FREQ} MHz" || FREQ="Unknown"
        CONNECTED_JSON=$(jq -n \
                  --arg id "$SSID" \
                  --arg ssid "$SSID" \
                  --arg icon "$ICON" \
                  --arg signal "$SIGNAL" \
                  --arg security "" \
                  --arg ip "$IP" \
                  --arg freq "$FREQ" \
                  '{id: $id, ssid: $ssid, icon: $icon, signal: $signal, security: $security, ip: $ip, freq: $freq}')
    fi
fi

NETWORKS_JSON="[]"
# Get available networks using nmcli if possible
if nmcli -t -f active,ssid,signal,security device wifi list --rescan no >/dev/null 2>&1; then
    NETWORKS_JSON=$(nmcli -t -f active,ssid,signal,security device wifi list --rescan no | \
        awk -F: '!seen[$2]++ && $2 != "" && $1 != "yes" {print $2":"$3":"$4}' | \
        head -n 24 | \
        while IFS=':' read -r ssid signal security; do
            icon=$(get_icon "$signal")
            jq -n \
               --arg id "$ssid" \
               --arg ssid "$ssid" \
               --arg icon "$icon" \
               --arg signal "$signal" \
               --arg security "$security" \
               '{id: $id, ssid: $ssid, icon: $icon, signal: $signal, security: $security}'
        done | jq -s '.')
fi

echo $(jq -n \
       --arg power "on" \
       --argjson connected "''${CONNECTED_JSON:-null}" \
       --argjson networks "''${NETWORKS_JSON:-[]}" \
       '{power: $power, connected: $connected, networks: $networks}')
SH
    # Override bluetooth panel logic to detect connected devices reliably
    cat > "$out/network/bluetooth_panel_logic.sh" <<'SH'
#!/usr/bin/env bash

HCITOOL="${pkgs.bluez}/bin/hcitool"
HCICONFIG="${pkgs.bluez}/bin/hciconfig"
HCITOOL="${pkgs.bluez}/bin/hcitool"
CACHE_DIR="/tmp/quickshell_network_cache"
mkdir -p "$CACHE_DIR"

get_icon() {
    local name
    name=$(echo "$1" | tr '[:upper:]' '[:lower:]')
    if [[ "$name" == *"headset"* ]] || [[ "$name" == *"headphone"* ]] || [[ "$name" == *"buds"* ]] || [[ "$name" == *"pods"* ]]; then echo "🎧"
    elif [[ "$name" == *"speaker"* ]]; then echo "󰓃"
    elif [[ "$name" == *"phone"* ]] || [[ "$name" == *"iphone"* ]] || [[ "$name" == *"android"* ]]; then echo "󰄜"
    elif [[ "$name" == *"mouse"* ]]; then echo "󰍽"
    elif [[ "$name" == *"keyboard"* ]]; then echo "󰌌"
    elif [[ "$name" == *"controller"* ]]; then echo "󰊴"
    else echo ""
    fi
}

bt_connected_macs() {
    $HCITOOL con 2>/dev/null | awk '/< LE|ACL/ {print $3}'
}

get_status() {
    power="off"
    connected_json="[]"
    devices_json="[]"

    connected_macs=$(bt_connected_macs)
    if [ -n "$connected_macs" ]; then
        power="on"
    else
        if $HCICONFIG 2>/dev/null | grep -q "UP RUNNING"; then power="on"; fi
    fi

    if [ "$power" = "on" ] && [ -n "$connected_macs" ]; then
        connected_list_objs=()
        for mac in $connected_macs; do
            name=$(timeout 2s bluetoothctl info "$mac" 2>/dev/null | awk -F': ' '/Name:/ {print $2; exit}')
            [ -z "$name" ] && name=$($HCITOOL name "$mac" 2>/dev/null)
            [ -z "$name" ] && name="$mac"
            icon=$(get_icon "$name")
            obj=$(jq -n -c                 --arg id "$mac"                 --arg name "$name"                 --arg mac "$mac"                 --arg icon "$icon"                 --arg bat "0"                 --arg profile "Connected"                 '{id: $id, name: $name, mac: $mac, icon: $icon, battery: $bat, profile: $profile}')
            connected_list_objs+=("$obj")
        done
        if [ ''${#connected_list_objs[@]} -gt 0 ]; then
            connected_json=$(printf '%s
' "''${connected_list_objs[*]}" | jq -s -c '.')
        fi
    fi

    jq -n -c         --arg power "$power"         --argjson connected "''${connected_json}"         --argjson devices "''${devices_json:-[]}"         '{power: $power, connected: $connected, devices: $devices}'
}

toggle_power() {
    if bluetoothctl show 2>/dev/null | grep -q "Powered: yes"; then
        bluetoothctl power off
    else
        bluetoothctl power on
    fi
    sleep 0.5
}

connect_dev() {
    local mac="$1"
    bluetoothctl trust "$mac" > /dev/null 2>&1
    bluetoothctl connect "$mac"
}

disconnect_dev() {
    local mac="$1"
    rm -f "/tmp/quickshell_network_cache/bt_stat_''${mac//:/_}" 2>/dev/null
    bluetoothctl disconnect "$mac"
}

cmd="$1"
case $cmd in
    --status) get_status ;;
    --toggle) toggle_power ;;
    --connect) connect_dev "$2" ;;
    --disconnect) disconnect_dev "$2" ;;
esac
SH
    awk '
    BEGIN{skip=0}
    /\/\/ Search/ {skip=1; next}
    skip {
        if (/\/\/ Notifications/) {skip=0; print; next}
        next
    }
    {print}
    ' "$out/TopBar.qml" > "$out/TopBar.qml.tmp"
    mv "$out/TopBar.qml.tmp" "$out/TopBar.qml"


    awk '
    BEGIN{inleft=0; skipped=0}
    /\/\/ ---------------- LEFT ----------------/ {inleft=1}
    inleft && /\/\/ Notifications/ {
        skipped=1
        next
    }
    inleft && skipped {
        if (/\/\/ Workspaces/) {skipped=0; print; next}
        next
    }
    {print}
    ' "$out/TopBar.qml" > "$out/TopBar.qml.tmp"
    mv "$out/TopBar.qml.tmp" "$out/TopBar.qml"

    # Remove Notifications block in right island (if present)
    awk '
    BEGIN{skip=0; brace=0; started=0}
    /\/\/ Notifications/ {skip=1; next}
    skip {
        if (!started && /Rectangle[[:space:]]*\\{/) {started=1}
        if (started) {
            brace += gsub(/\\{/, "{");
            brace -= gsub(/\\}/, "}");
            if (brace <= 0) {skip=0; next}
        }
        next
    }
    {print}
    ' "$out/TopBar.qml" > "$out/TopBar.qml.tmp"
    mv "$out/TopBar.qml.tmp" "$out/TopBar.qml"
    awk '
    BEGIN{skip_kb=0; skip_bat=0; brace=0; started=0}
    /\/\/ KB/ {skip_kb=1; next}
    skip_kb {
        if (/\/\/ WiFi/) {skip_kb=0; print; next}
        next
    }
    /\/\/ Battery/ {skip_bat=1; brace=0; started=0; next}
    skip_bat {
        if (!started && /Rectangle[[:space:]]*\{/) {started=1}
        if (started) {
            brace += gsub(/\{/, "{");
            brace -= gsub(/\}/, "}");
            if (brace <= 0) {skip_bat=0; next}
        }
        next
    }
    {print}
    ' "$out/TopBar.qml" > "$out/TopBar.qml.tmp"
    mv "$out/TopBar.qml.tmp" "$out/TopBar.qml"
    cat > "$out/workspaces.sh" <<'SH'
#!/usr/bin/env bash

SEQ_END=8
OUT_FILE="$1"
if [ -z "$OUT_FILE" ]; then
    OUT_FILE="/tmp/qs_workspaces.json"
fi

print_workspaces() {
    local spaces active
    spaces=$(hyprctl workspaces -j 2>/dev/null || echo "[]")
    active=$(hyprctl activeworkspace -j 2>/dev/null | jq '.id' 2>/dev/null)

    local payload
    payload=$(echo "$spaces" | jq --argjson a "$active" --arg end "$SEQ_END" -c '
        (map( { (.id|tostring): . } ) | add) as $s
        |
        [range(1; ($end|tonumber) + 1)] | map(
            . as $i |
            (if $i == $a then "active"
             elif ($s[$i|tostring] != null and $s[$i|tostring].windows > 0) then "occupied"
             else "empty" end) as $state |
            (if $s[$i|tostring] != null then $s[$i|tostring].lastwindowtitle else "Empty" end) as $win |
            { id: $i, state: $state, tooltip: $win }
        )
    ')
    printf '%s\n' "$payload" > "$OUT_FILE"
}

print_workspaces

SOCKET="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"
if [ -S "$SOCKET" ]; then
    socat -u UNIX-CONNECT:"$SOCKET" - | while read -r line; do
        case "$line" in
            workspace*|openwindow*|closewindow*|movewindow*|activewindow*|activespecial*|createwindow*|movewindowv2*)
                print_workspaces
                ;;
        esac
    done
else
    while true; do
        print_workspaces
        sleep 1
    done
fi
SH
    chmod +x "$out/workspaces.sh"
    # Replace schedule scripts with Google Calendar fetcher
    cat > "$out/calendar/schedule/schedule_manager.sh" <<'SH'
#!/usr/bin/env bash

CACHE_DIR="$HOME/.cache/eww/schedule"
CACHE_FILE="$CACHE_DIR/schedule.json"
CACHE_LIMIT=600

SHELL_NIX="$HOME/.config/hypr/scripts/quickshell/calendar/schedule/shell.nix"
UPDATER_SCRIPT="$HOME/.config/hypr/scripts/quickshell/calendar/schedule/get_schedule.py"

mkdir -p "$CACHE_DIR"

trigger_update() {
    if pgrep -f "python3.*get_schedule.py" > /dev/null; then
        return
    fi
    nix-shell "$SHELL_NIX" --run "python3 '$UPDATER_SCRIPT'" >/dev/null 2>&1 &
}

if [ -f "$CACHE_FILE" ]; then
    cat "$CACHE_FILE"
    current_time=$(date +%s)
    file_time=$(stat -c %Y "$CACHE_FILE")
    age=$((current_time - file_time))
    if [ "$age" -gt "$CACHE_LIMIT" ]; then
        trigger_update
    fi
else
    echo '{ "header": "Loading...", "lessons": [], "link": "" }'
    trigger_update
fi
SH
    chmod +x "$out/calendar/schedule/schedule_manager.sh"

    cat > "$out/calendar/schedule/get_schedule.py" <<'PY'
#!/usr/bin/env python3
import json
import os
import sys
from datetime import datetime, timedelta, time as dtime
from urllib.parse import quote

from google.oauth2.credentials import Credentials
from google_auth_oauthlib.flow import InstalledAppFlow
from google.auth.transport.requests import Request
from googleapiclient.discovery import build

SCOPES = ["https://www.googleapis.com/auth/calendar.readonly"]

CREDENTIALS_FILE = os.path.expanduser(
    os.environ.get("QS_GCAL_CREDENTIALS", "~/.config/hypr/qs-gcal-credentials.json")
)
TOKEN_FILE = os.path.expanduser(
    os.environ.get("QS_GCAL_TOKEN", "~/.config/hypr/qs-gcal-token.json")
)
CALENDAR_ID = os.environ.get("QS_GCAL_ID", "primary")
DAY_START = os.environ.get("QS_GCAL_DAY_START", "08:00")
DAY_END = os.environ.get("QS_GCAL_DAY_END", "20:00")

TOTAL_AVAILABLE_WIDTH_PX = 750

def parse_hhmm(s, fallback):
    try:
        h, m = s.split(":")
        return dtime(int(h), int(m))
    except Exception:
        return fallback

def to_epoch(dt):
    return int(dt.timestamp())

def build_link(date_obj):
    base = "https://calendar.google.com/calendar/u/0/r/day"
    date_part = date_obj.strftime("%Y/%m/%d")
    if CALENDAR_ID == "primary":
        return f"{base}/{date_part}"
    return f"{base}/{date_part}?cid={quote(CALENDAR_ID)}"

def get_credentials():
    if not os.path.exists(CREDENTIALS_FILE):
        return None
    creds = None
    if os.path.exists(TOKEN_FILE):
        creds = Credentials.from_authorized_user_file(TOKEN_FILE, SCOPES)
    if creds and creds.expired and creds.refresh_token:
        creds.refresh(Request())
        with open(TOKEN_FILE, "w") as f:
            f.write(creds.to_json())
    if creds and creds.valid:
        return creds
    # No token: require manual auth
    return None

def ensure_cache(output):
    cache_dir = os.path.expanduser("~/.cache/eww/schedule")
    os.makedirs(cache_dir, exist_ok=True)
    cache_file = os.path.join(cache_dir, "schedule.json")
    with open(cache_file, "w") as f:
        json.dump(output, f, ensure_ascii=False)
    print(json.dumps(output, ensure_ascii=False))

def main():
    creds = get_credentials()
    if creds is None:
        output = {
            "header": "Google Calendar not configured",
            "lessons": [],
            "link": ""
        }
        ensure_cache(output)
        return

    service = build("calendar", "v3", credentials=creds)

    now = datetime.now().astimezone()
    start_time = datetime.combine(now.date(), parse_hhmm(DAY_START, dtime(8, 0))).astimezone()
    end_time = datetime.combine(now.date(), parse_hhmm(DAY_END, dtime(20, 0))).astimezone()

    events_result = service.events().list(
        calendarId=CALENDAR_ID,
        timeMin=start_time.isoformat(),
        timeMax=end_time.isoformat(),
        singleEvents=True,
        orderBy="startTime",
        maxResults=50,
    ).execute()
    events = events_result.get("items", [])

    total_minutes = (end_time - start_time).total_seconds() / 60.0
    ppm = TOTAL_AVAILABLE_WIDTH_PX / total_minutes if total_minutes > 0 else 1.5

    lessons = []
    cursor = to_epoch(start_time)
    end_cursor = to_epoch(end_time)

    def add_gap(start, end):
        duration = max(0, end - start)
        if duration <= 60:
            return
        width = int((duration / 60.0) * ppm)
        lessons.append({
            "type": "gap",
            "width": width,
            "desc": f"{int(duration/60)}m",
            "start": start,
            "end": end,
        })

    for ev in events:
        start_str = ev["start"].get("dateTime") or ev["start"].get("date")
        end_str = ev["end"].get("dateTime") or ev["end"].get("date")
        if not start_str or not end_str:
            continue
        try:
            start_dt = datetime.fromisoformat(start_str)
            end_dt = datetime.fromisoformat(end_str)
        except Exception:
            continue

        start_epoch = to_epoch(start_dt)
        end_epoch = to_epoch(end_dt)

        if start_epoch > cursor:
            add_gap(cursor, start_epoch)
            cursor = start_epoch

        duration = max(0, end_epoch - cursor)
        width = int((duration / 60.0) * ppm)
        char_limit = int(width / 5) if width > 0 else 10

        lessons.append({
            "type": "class",
            "time": f"{start_dt.strftime('%H:%M')}-{end_dt.strftime('%H:%M')}",
            "subject": ev.get("summary", "Untitled"),
            "room": ev.get("location", ""),
            "teacher": ev.get("organizer", {}).get("displayName", ""),
            "start": start_epoch,
            "end": end_epoch,
            "width": width,
            "char_limit": char_limit,
            "is_compact": width < 70,
        })
        cursor = end_epoch

    if cursor < end_cursor:
        add_gap(cursor, end_cursor)

    header = now.strftime("%A, %d %b (Today)")
    output = {
        "header": header,
        "lessons": lessons,
        "link": build_link(now),
    }
    ensure_cache(output)

PY
    chmod +x "$out/calendar/schedule/get_schedule.py"
    cat >> "$out/calendar/schedule/get_schedule.py" <<'PY'

if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        output = {
            "header": f"Schedule Error: {e}",
            "lessons": [],
            "link": ""
        }
        ensure_cache(output)
        print(f"Schedule Error: {e}", file=sys.stderr)
PY

    cat > "$out/calendar/schedule/shell.nix" <<'NIX'
{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    python3
    python3Packages.google-api-python-client
    python3Packages.google-auth
    python3Packages.google-auth-oauthlib
    python3Packages.google-auth-httplib2
  ];
}
NIX
    awk '
      /^RESOURCE_ID =/ { print "RESOURCE_ID = os.environ.get(\"QS_RESOURCE_ID\", \"\")"; next }
      /^PROFILE_PATH =/ { print "PROFILE_PATH = os.environ.get(\"QS_FIREFOX_PROFILE\", \"\")"; next }
      { print }
    ' "$out/calendar/schedule/get_schedule.py" > "$out/calendar/schedule/get_schedule.py.tmp"
    mv "$out/calendar/schedule/get_schedule.py.tmp" "$out/calendar/schedule/get_schedule.py"
    awk '
      /^def update_schedule\\(\\):/ {
        print;
        print "    if not RESOURCE_ID or not PROFILE_PATH or not os.path.exists(PROFILE_PATH):";
        print "        output = {\"header\": \"Schedule not configured\", \"lessons\": [], \"link\": \"\"}";
        print "        print(json.dumps(output))";
        print "        return";
        next
      }
      { print }
    ' "$out/calendar/schedule/get_schedule.py" > "$out/calendar/schedule/get_schedule.py.tmp"
    mv "$out/calendar/schedule/get_schedule.py.tmp" "$out/calendar/schedule/get_schedule.py"
    sed -i '/--icon/,$d' "$out/calendar/weather.sh"
    cat >> "$out/calendar/weather.sh" <<'SH'
elif [[ "$1" == "--icon" ]]; then
    [ -f "$json_file" ] || get_data
    if [ -f "$json_file" ]; then cat "$json_file" | jq -r '.forecast[0].icon'; else echo "?"; fi
elif [[ "$1" == "--temp" ]]; then
    [ -f "$json_file" ] || get_data
    if [ -f "$json_file" ]; then t=$(cat "$json_file" | jq -r '.forecast[0].max'); echo "$t°C"; else echo "--°"; fi
elif [[ "$1" == "--hex" ]]; then
    [ -f "$json_file" ] || get_data
    if [ -f "$json_file" ]; then cat "$json_file" | jq -r '.forecast[0].hex'; else echo "#f9e2af"; fi
fi
SH
  '';
  qsManagerScript = pkgs.writeShellScript "qs_manager.sh" ''
    #!/usr/bin/env bash

    QS_DIR="$(cd "$(dirname "''${BASH_SOURCE[0]}")" && pwd)/quickshell"
    BT_PID_FILE="$HOME/.cache/bt_scan_pid"
    BT_SCAN_LOG="$HOME/.cache/bt_scan.log"
    SRC_DIR="$HOME/Images/Wallpapers"
    THUMB_DIR="$HOME/.cache/wallpaper_picker/thumbs"

    IPC_FILE="/tmp/qs_widget_state"
    ACTION="$1"
    TARGET="$2"

    handle_wallpaper_prep() {
        mkdir -p "$THUMB_DIR"
        (
            for thumb in "$THUMB_DIR"/*; do
                [ -e "$thumb" ] || continue
                filename=$(basename "$thumb")
                clean_name="''${filename#000_}"
                if [ ! -f "$SRC_DIR/$clean_name" ]; then
                    rm -f "$thumb"
                fi
            done

            for img in "$SRC_DIR"/*.{jpg,jpeg,png,webp,gif,mp4,mkv,mov,webm}; do
                [ -e "$img" ] || continue
                filename=$(basename "$img")
                extension="''${filename##*.}"

                if [[ "''${extension,,}" =~ ^(mp4|mkv|mov|webm)$ ]]; then
                    thumb="$THUMB_DIR/000_$filename"
                    [ -f "$THUMB_DIR/$filename" ] && rm -f "$THUMB_DIR/$filename"
                    if [ ! -f "$thumb" ]; then
                         ffmpeg -y -ss 00:00:05 -i "$img" -vframes 1 -f image2 -q:v 2 "$thumb" > /dev/null 2>&1
                    fi
                else
                    thumb="$THUMB_DIR/$filename"
                    if [ ! -f "$thumb" ]; then
                        magick "$img" -resize x420 -quality 70 "$thumb"
                    fi
                fi
            done
        ) &

        TARGET_INDEX=0
        CURRENT_SRC=""

        if pgrep -a "mpvpaper" > /dev/null; then
            CURRENT_SRC=$(pgrep -a mpvpaper | grep -o "$SRC_DIR/[^' ]*" | head -n1)
            CURRENT_SRC=$(basename "$CURRENT_SRC")
        fi

        if [ -z "$CURRENT_SRC" ] && command -v swww >/dev/null; then
            CURRENT_SRC=$(swww query 2>/dev/null | grep -o "$SRC_DIR/[^ ]*" | head -n1)
            CURRENT_SRC=$(basename "$CURRENT_SRC")
        fi

        if [ -n "$CURRENT_SRC" ]; then
            EXT="''${CURRENT_SRC##*.}"
            if [[ "''${EXT,,}" =~ ^(mp4|mkv|mov|webm)$ ]]; then
                TARGET_THUMB="000_$CURRENT_SRC"
            else
                TARGET_THUMB="$CURRENT_SRC"
            fi

            MATCH_LINE=$(ls -1 "$THUMB_DIR" | grep -nF "$TARGET_THUMB" | cut -d: -f1)
            if [ -n "$MATCH_LINE" ]; then
                TARGET_INDEX=$((MATCH_LINE - 1))
            fi
        fi
        export WALLPAPER_INDEX="$TARGET_INDEX"
    }

    handle_network_prep() {
        echo "" > "$BT_SCAN_LOG"
        { echo "scan on"; sleep infinity; } | stdbuf -oL bluetoothctl > "$BT_SCAN_LOG" 2>&1 &
        echo $! > "$BT_PID_FILE"
        (nmcli device wifi rescan) &
    }

    move_qs_master_to_cursor_workspace() {
        local cursor_json monitor_json active_json target_ws qs_addr prev_addr
        active_json=$(hyprctl -j activewindow 2>/dev/null || echo "")
        if [ -n "$active_json" ]; then
            target_ws=$(jq -r '.workspace.id // empty' <<<"$active_json")
        fi
        if [ -z "$target_ws" ] || [ "$target_ws" = "null" ]; then
            cursor_json=$(hyprctl -j cursorpos 2>/dev/null || echo "")
            monitor_json=$(hyprctl -j monitors 2>/dev/null || echo "")
            if [ -n "$cursor_json" ] && [ -n "$monitor_json" ]; then
                target_ws=$(jq -r --argjson cursor "$cursor_json" '
                    map(select(
                        ($cursor.x >= .x) and ($cursor.x < (.x + .width)) and
                        ($cursor.y >= .y) and ($cursor.y < (.y + .height))
                    ))[0].activeWorkspace.id // empty
                ' <<<"$monitor_json")
            fi
        fi
        if [ -n "$target_ws" ]; then
            qs_addr=$(hyprctl clients -j | jq -r '.[] | select(.title=="qs-master") | .address' | head -n1)
            if [ -n "$qs_addr" ]; then
                hyprctl dispatch movetoworkspacesilent "$target_ws,address:$qs_addr" >/dev/null 2>&1 \
                  || hyprctl dispatch movetoworkspace "$target_ws,address:$qs_addr" >/dev/null 2>&1
            else
                hyprctl dispatch movetoworkspacesilent "$target_ws" >/dev/null 2>&1 \
                  || hyprctl dispatch movetoworkspace "$target_ws" >/dev/null 2>&1
            fi
        fi
    }

    # -----------------------------------------------------------------------------
    # ENSURE MASTER WINDOW & TOP BAR ARE ALIVE (ZOMBIE WATCHDOG)
    # -----------------------------------------------------------------------------
    QS_PID=$(pgrep -f "quickshell.*Main\\.qml")
    WIN_EXISTS=$(hyprctl clients -j | grep "qs-master")

    BAR_PID=$(pgrep -f "quickshell.*TopBar\\.qml")

    # 1. Manage the Master morphing window
    if [[ -z "$QS_PID" ]] || [[ -z "$WIN_EXISTS" ]]; then
        if [[ -n "$QS_PID" ]]; then
            kill -9 $QS_PID 2>/dev/null
        fi
        quickshell -p "$QS_DIR/Main.qml" >/dev/null 2>&1 &
        disown
        sleep 0.6 
    fi

    # 2. Manage the persistent Top Bar
    if [[ -z "$BAR_PID" ]]; then
        quickshell -p "$QS_DIR/TopBar.qml" >/dev/null 2>&1 &
        disown
    fi

    # -----------------------------------------------------------------------------
    # MAIN LOGIC
    # -----------------------------------------------------------------------------
    if [[ "$ACTION" =~ ^[0-9]+$ ]]; then
        WORKSPACE_NUM="$ACTION"
        MOVE_OPT="$2"
        echo "close" > "$IPC_FILE"
        if [[ "$MOVE_OPT" == "move" ]]; then
            hyprctl dispatch movetoworkspace "$WORKSPACE_NUM"
        else
            hyprctl dispatch workspace "$WORKSPACE_NUM"
        fi
        exit 0
    fi

    if [[ "$ACTION" == "close" ]]; then
        echo "close" > "$IPC_FILE"
        if [[ "$TARGET" == "network" || "$TARGET" == "all" || -z "$TARGET" ]]; then
            if [ -f "$BT_PID_FILE" ]; then
                kill $(cat "$BT_PID_FILE") 2>/dev/null
                rm -f "$BT_PID_FILE"
            fi
            bluetoothctl scan off > /dev/null 2>&1
        fi
        exit 0
    fi

    if [[ "$ACTION" == "open" || "$ACTION" == "toggle" ]]; then
        if [[ "$TARGET" == "network" ]]; then
            handle_network_prep
            echo "$TARGET" > "$IPC_FILE"
        elif [[ "$TARGET" == "wallpaper" ]]; then
            handle_wallpaper_prep
            echo "$TARGET:$WALLPAPER_INDEX" > "$IPC_FILE"
        else
            echo "$TARGET" > "$IPC_FILE"
        fi
        (
            move_qs_master_to_cursor_workspace
            sleep 0.12
            move_qs_master_to_cursor_workspace
        ) >/dev/null 2>&1 &
        exit 0
    fi
  '';
  quicksnipScript = pkgs.writeShellScript "quicksnip" ''
    exec env \
      QT_QML_IMPORT_PATH=${pkgs.qt6Packages.qt5compat}/lib/qt-6/qml \
      QML2_IMPORT_PATH=${pkgs.qt6Packages.qt5compat}/lib/qt-6/qml \
      QSG_RHI_BACKEND=software \
      QT_QUICK_BACKEND=software \
      quickshell -c QuickSnip -n
  '';
in {

  imports = [
    ./animations.nix
    ./bindings.nix
    ./polkitagent.nix
    #./hyprspace.nix
  ];

  home.packages = with pkgs; [
    qt5.qtwayland
    qt6.qtwayland
    libsForQt5.qt5ct
    qt5.qtgraphicaleffects
    qt6Packages.qt5compat
    qt6ct
    hyprshot
    hyprpicker
    socat
    swaynotificationcenter
    pulseaudio
    grim
    imagemagick
    tesseract
    wl-clipboard
    curl
    libnotify
    xdg-utils
    swappy
    imv
    wf-recorder
    wlr-randr
    brightnessctl
    gnome-themes-extra
    libva
    dconf
    wayland-utils
    wayland-protocols
    glib
    direnv
    meson
    wlogout
  ];

  wayland.windowManager.hyprland = {
    enable = true;
    xwayland.enable = true;
    systemd.enable = true;
    #package = inputs.hyprland.packages."${pkgs.system}".hyprland;
    package = pkgs.hyprland;

    settings = {
      "$mod" = "SUPER";
      "$shiftMod" = "SUPER_SHIFT";

      exec-once = [
        #"${pkgs.bitwarden}/bin/bitwarden"
        "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
        "fcitx5 -d --replace" # for typing zhuyin
        "swaync"
        "/etc/profiles/per-user/${config.var.username}/bin/awww-daemon"
        #"/etc/profiles/per-user/${config.var.username}/bin/matuwall --daemon"
        #"sleep 0.1 && /etc/profiles/per-user/${config.var.username}/bin/matuwall --reload"
      ] ++ lib.optionals (config.var.bar == "topbar") [
        "quickshell -p /home/${config.var.username}/.config/hypr/scripts/quickshell/TopBar.qml"
      ];

      #monitor = [
      #  "eDP-2,highres,0x0,1"
      #  "DP-7, disable"
      #  "DP-8, disable"
      #  "DP-9, disable"
      #  "HDMI-A-1,3440x1440@99.98,auto,1"
      #  ",prefered,auto,1"
      #];

      monitor = [
        "DP-3,3440x1440@99.98,0x0,1"
        #"DP-7, disable"
        #"DP-8, disable"
        #"DP-9, disable"
        "HDMI-A-2,1920x1080@60,320x-1080,1"
        #",prefered,auto,1"
      ];

      env = [
        "XDG_SESSION_TYPE,wayland"
        "XDG_CURRENT_DESKTOP,Hyprland"
        "MOZ_ENABLE_WAYLAND,1"
        "ANKI_WAYLAND,1"
        "DISABLE_QT5_COMPAT,0"
        "NIXOS_OZONE_WL,1"
        "XDG_SESSION_TYPE,wayland"
        "XDG_SESSION_DESKTOP,Hyprland"
        "QT_AUTO_SCREEN_SCALE_FACTOR,1"
        "QT_QPA_PLATFORM=wayland,xcb"
        "QT_WAYLAND_DISABLE_WINDOWDECORATION,1"
        "QT_QML_IMPORT_PATH,${pkgs.qt6Packages.qt5compat}/lib/qt-6/qml"
        "QML2_IMPORT_PATH,${pkgs.qt6Packages.qt5compat}/lib/qt-6/qml"
        "ELECTRON_OZONE_PLATFORM_HINT,auto"
        # "GTK_THEME,FlatColor:dark"
        # "GTK2_RC_FILES,/home/hadi/.local/share/themes/FlatColor/gtk-2.0/gtkrc"

        #### for fcitx5 ####
        "GTK_IM_MODULE,fcitx"
        "QT_IM_MODULE,fcitx"
        "XMODIFIERS,@im=fcitx"
        "SDL_IM_MODULE,fcitx"
        ####################

        "__GL_GSYNC_ALLOWED,0"
        "__GL_VRR_ALLOWED,0"
        "DISABLE_QT5_COMPAT,0"
        "DIRENV_LOG_FORMAT,"
        "WLR_DRM_NO_ATOMIC,1"
        "WLR_BACKEND,vulkan"
        "WLR_RENDERER,vulkan"
        "WLR_NO_HARDWARE_CURSORS,1"
        "XDG_SESSION_TYPE,wayland"
        "SDL_VIDEODRIVER,wayland"
        "CLUTTER_BACKEND,wayland"
        "AQ_DRM_DEVICES,/dev/dri/card2:/dev/dri/card1" # CHANGEME: Related to the GPU
      ];

      cursor = {
        no_hardware_cursors = true;
        default_monitor = "DP-3"; # CHANGEME: Related to the monitor
      };

      general = {
        resize_on_border = true;
        gaps_in = gaps-in;
        gaps_out = gaps-out;
        border_size = border-size;
        layout = "master";
      };

      decoration = {
        active_opacity = active-opacity;
        inactive_opacity = inactive-opacity;
        rounding = rounding;
        border_part_of_window = true;
        shadow = {
          enabled = true;
          range = 20;
          render_power = 3;
        };
        blur = { enabled = if blur then "true" else "false"; };
      };

      master = {
        new_status = true;
        allow_small_split = true;
        mfact = 0.5;
      };

      gesture = [ "4, horizontal, workspace" ];

      misc = {
        vfr = true;
        disable_hyprland_logo = true;
        disable_splash_rendering = true;
        disable_autoreload = true;
        focus_on_activate = true;
        #new_window_takes_over_fullscreen = 2;
        on_focus_under_fullscreen = 2;
      };

      workspace = [ "8, layout:scrolling" ];

      #windowrulev2 = [
      #"float, title:^(qs-master)$"
      #"stayfocused, title:^(qs-master)$"
      #];
      windowrule = [
        "float on, match:tag modal"
        "pin on, match:tag modal"
        "center on, match:tag modal"
        "float on, match:title ^(qs-master)$"
        "pin on, match:title ^(qs-master)$"
      ];

      layerrule = [
        "no_anim on, match:namespace launcher"
        "no_anim on, match:namespace ^ags-.*"
        "blur on, match:namespace swaync-notification-window"
      ];

      input = {
        kb_layout = keyboardLayout;

        kb_options = "caps:escape";
        follow_mouse = 1;
        sensitivity = 0.5;
        repeat_delay = 300;
        repeat_rate = 50;
        numlock_by_default = true;

        touchpad = {
          natural_scroll = true;
          clickfinger_behavior = true;
        };
      };

    };
  };
  xdg.configFile = lib.mkIf (config.var.bar == "topbar") {
    "hypr/scripts/quickshell".source = quickshellDir;
    "hypr/scripts/qs_manager.sh" = {
      source = qsManagerScript;
      executable = true;
    };
    "hypr/scripts/quicksnip.sh" = {
      source = quicksnipScript;
      executable = true;
    };
    "hypr/scripts/Main.qml".source =
      "${thirdpartyRoot}/config/sessions/hyprland/scripts/quickshell/Main.qml";
    "hypr/scripts/TopBar.qml".source =
      "${thirdpartyRoot}/config/sessions/hyprland/scripts/quickshell/TopBar.qml";
    "swaync".source = "${quickshellDir}/swaync";
    "quickshell/QuickSnip".source =
      config.lib.file.mkOutOfStoreSymlink "/home/${config.var.username}/.config/nixos/thirdparty/QuickSnip";
    "hypr/scripts/qs_wallpaper/qs_manager.sh" = {
      source = "${../../../home/programs/quickshell-wallpaper/files/qs_manager.sh}";
      executable = true;
    };
    "hypr/scripts/qs_wallpaper/quickshell".source =
      "${../../../home/programs/quickshell-wallpaper/files/quickshell}";
  };
  systemd.user.targets.hyprland-session.Unit.Wants =
    [ "xdg-desktop-autostart.target" ];
}
