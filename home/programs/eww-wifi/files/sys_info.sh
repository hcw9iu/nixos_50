#!/usr/bin/env bash

get_wifi_status() {
    nmcli -t -f WIFI g 2>/dev/null || echo "disabled"
}

get_wifi_ssid() {
    local ssid
    ssid=$(nmcli -t -f ACTIVE,SSID dev wifi 2>/dev/null | grep '^yes' | cut -d: -f2)
    if [ -z "$ssid" ]; then
        echo ""
    else
        echo "$ssid"
    fi
}

get_wifi_strength() {
    local signal
    signal=$(nmcli -f IN-USE,SIGNAL dev wifi 2>/dev/null | grep '^\*' | awk '{print $2}')
    echo "${signal:-0}"
}

get_wifi_icon() {
    local status ssid signal
    status=$(get_wifi_status)
    ssid=$(get_wifi_ssid)

    if [ "$status" = "enabled" ]; then
        if [ -n "$ssid" ]; then
            signal=$(get_wifi_strength)
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
            echo "󰤯"
        fi
    else
        echo "󰤮"
    fi
}

case "$1" in
  --wifi-status)
    get_wifi_status
    ;;
  --wifi-icon)
    get_wifi_icon
    ;;
  --wifi-ssid)
    get_wifi_ssid
    ;;
  *)
    exit 0
    ;;
esac
