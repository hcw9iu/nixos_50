#!/usr/bin/env bash

CFG="$HOME/.config/eww/qs-wifi"
LOG="$HOME/.cache/eww_wifi.log"

mkdir -p "$HOME/.cache"
{
  echo "---- $(date) ----"
  eww --config "$CFG" daemon
  eww --config "$CFG" open wifi_bar
} >>"$LOG" 2>&1
