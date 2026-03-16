# 軟體版本紀錄

本文件用來記錄系統內「主要支撐軟體」的版本或來源，用於除錯與升級參考。
若版本是由 flake pin 或外部 repo 決定，請在更新後同步修改此文件。

## 核心
- Hyprland: 0.54.0+date=2026-02-27_0002f14

## 相關元件
- xdg-desktop-portal-hyprland: 1.3.11+date=2025-10-17_753bbbd
- hypridle: 0.1.7+date=2025-08-27_5430b73
- hyprlock: 0.9.2+date=2025-10-02_c48279d
- hyprpaper: 0.8.3+date=2026-01-29_64b991c
- swaync (swaynotificationcenter): 0.10.1
- wlogout: 1.2.2
- NetworkManager: 1.48.10
- BlueZ: 5.78
- PipeWire: 1.2.5
- WirePlumber: 0.5.6
- waybar: 0.11.0
- wofi: 1.4.1
- kitty: 0.37.0
- pamixer: 1.6

## 備註
- 若要查來源 pin，可參考 `flake.nix` 與 `flake.lock`。
- Hyprland 的版本對齊建議參考 `docs/UPGRADE.md`。
 - quickshell / rofi 在目前 nixpkgs 評估不到版本（可能由第三方或其他方式提供）。
