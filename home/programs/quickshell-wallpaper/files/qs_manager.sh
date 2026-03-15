#!/usr/bin/env bash

QS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/quickshell"
BT_PID_FILE="$HOME/.cache/bt_scan_pid"
BT_SCAN_LOG="$HOME/.cache/bt_scan.log"
SRC_DIR="$HOME/Pictures/WallPaper"
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
            clean_name="${filename#000_}"
            if [ ! -f "$SRC_DIR/$clean_name" ]; then
                rm -f "$thumb"
            fi
        done

        for img in "$SRC_DIR"/*.{jpg,jpeg,png,webp,gif,mp4,mkv,mov,webm}; do
            [ -e "$img" ] || continue
            filename=$(basename "$img")
            extension="${filename##*.}"

            if [[ "${extension,,}" =~ ^(mp4|mkv|mov|webm)$ ]]; then
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
    CURRENT_SRC_PATH=""

    if pgrep -a "mpvpaper" > /dev/null; then
        CURRENT_SRC_PATH=$(pgrep -a mpvpaper | grep -o "$SRC_DIR/[^' ]*" | head -n1)
        CURRENT_SRC=$(basename "$CURRENT_SRC_PATH")
    fi

    if [ -z "$CURRENT_SRC" ] && command -v swww >/dev/null; then
        CURRENT_SRC_PATH=$(swww query 2>/dev/null | grep -o "$SRC_DIR/[^ ]*" | head -n1)
        CURRENT_SRC=$(basename "$CURRENT_SRC_PATH")
    fi

    if [ -n "$CURRENT_SRC" ]; then
        if [ -z "$CURRENT_SRC_PATH" ]; then
            CURRENT_SRC_PATH="$SRC_DIR/$CURRENT_SRC"
        fi
        EXT="${CURRENT_SRC##*.}"
        if [[ "${EXT,,}" =~ ^(mp4|mkv|mov|webm)$ ]]; then
            TARGET_THUMB="000_$CURRENT_SRC"
        else
            TARGET_THUMB="$CURRENT_SRC"
        fi

        MATCH_LINE=$(ls -1 "$THUMB_DIR" | grep -nF "$TARGET_THUMB" | cut -d: -f1)
        if [ -n "$MATCH_LINE" ]; then
            TARGET_INDEX=$((MATCH_LINE - 1))
        fi

        # Sync lockscreen wallpaper to current wallpaper when opening picker
        "$HOME/.config/hypr/scripts/update_lock_wallpaper.sh" "${CURRENT_SRC_PATH:-}" >/dev/null 2>&1 || true
    fi
    if [ "$TARGET_INDEX" -eq 0 ]; then
        COUNT=$(ls -1 "$THUMB_DIR" 2>/dev/null | wc -l | tr -d ' ')
        if [ -n "$COUNT" ] && [ "$COUNT" -gt 0 ]; then
            TARGET_INDEX=$((COUNT / 2))
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

# -----------------------------------------------------------------------------
# ENSURE MASTER WINDOW & TOP BAR ARE ALIVE (ZOMBIE WATCHDOG)
# -----------------------------------------------------------------------------
QS_PID=$(pgrep -f "quickshell.*Main\.qml")
WIN_EXISTS=$(hyprctl clients -j | grep "qs-master")

# 1. Manage the Master morphing window
if [[ -z "$QS_PID" ]] || [[ -z "$WIN_EXISTS" ]]; then
    if [[ -n "$QS_PID" ]]; then
        kill -9 $QS_PID 2>/dev/null
    fi
    quickshell -p "$QS_DIR/Main.qml" >/dev/null 2>&1 &
    disown
    sleep 0.6 
fi

# Ensure the popup gets focus on every call
hyprctl dispatch focuswindow "title:^(qs-master)$" >/dev/null 2>&1

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
    exit 0
fi
