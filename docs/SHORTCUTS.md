# Shortcuts

目前依據：
- `hosts/desktop/variables.nix`：`bar = "topbar"`
- `home/system/hyprland/default.nix`：`$mod = SUPER`、`$shiftMod = SUPER_SHIFT`
- `home/system/hyprland/bindings.nix`

## 說明

- `SUPER` = Windows 鍵 / Meta 鍵
- `SUPER_SHIFT` = `SUPER + SHIFT`
- 以下為目前實際啟用的 Hyprland 綁定

## 應用程式與面板

| 快捷鍵 | 動作 |
|---|---|
| `SUPER + Enter` | 開啟 Kitty |
| `SUPER + E` | 開啟 Thunar |
| `SUPER + B` | 開啟 qutebrowser |
| `SUPER + K` | 開啟 Bitwarden |
| `SUPER + L` | 鎖定螢幕（先更新 lock wallpaper，再啟動 hyprlock） |
| `SUPER + X` | 開啟 `wlogout-menu` |
| `SUPER + Z` | 開啟 `powermenu` |
| `SUPER + Space` | 開啟 launcher（`menu`） |
| `SUPER + C` | 開啟 `quickmenu` |
| `SUPER + W` | 切換 `matuwall` |
| `SUPER + SHIFT + W` | 開啟 Quickshell wallpaper picker |
| `SUPER + SHIFT + Space` | 切換 `hyprfocus-toggle` |
| `SUPER + SHIFT + T` | 開啟 QuickSnip（僅 `bar = topbar` 時啟用） |

## 視窗管理

| 快捷鍵 | 動作 |
|---|---|
| `SUPER + Q` | 關閉目前視窗 |
| `SUPER + T` | 切換浮動視窗 |
| `SUPER + F` | 切換全螢幕 |
| `SUPER + Left` | 將焦點移到左側視窗 |
| `SUPER + Right` | 將焦點移到右側視窗 |
| `SUPER + Up` | 將焦點移到上方視窗 |
| `SUPER + Down` | 將焦點移到下方視窗 |
| `SUPER + Tab` | 在目前與上一個視窗之間切換焦點 |
| `SUPER + Mouse Left` | 拖曳移動視窗 |
| `SUPER + R` | 以滑鼠調整視窗大小 |

## 多螢幕與 master layout

| 快捷鍵 | 動作 |
|---|---|
| `SUPER + SHIFT + Up` | 聚焦上一個螢幕 |
| `SUPER + SHIFT + Down` | 聚焦下一個螢幕 |
| `SUPER + SHIFT + Left` | 將視窗加入 master |
| `SUPER + SHIFT + Right` | 將視窗移出 master |

## 工作區

| 快捷鍵 | 動作 |
|---|---|
| `SUPER + 1..9` | 切換到工作區 `1..9` |
| `SUPER + SHIFT + 1..9` | 將目前視窗移到工作區 `1..9` |

## 截圖

| 快捷鍵 | 動作 |
|---|---|
| `SUPER + Print` | 截取目前視窗 |
| `CTRL + ALT + P` | 截取目前螢幕 |
| `SUPER + SHIFT + Print` | 區域截圖 |
| `ALT + Print` | 區域截圖後交給 Swappy 編輯 |

## 搜尋、剪貼簿、Emoji

| 快捷鍵 | 動作 |
|---|---|
| `SUPER + SHIFT + S` | 用 wofi 輸入關鍵字，交給 qutebrowser 搜尋 |
| `SUPER + SHIFT + C` | 開啟剪貼簿選單 |
| `SUPER + SHIFT + E` | 開啟 Emoji picker |

## 顯示與色溫

| 快捷鍵 | 動作 |
|---|---|
| `SUPER + F2` | 切換 `night-shift` |
| `SUPER + F3` | 切換 `night-shift` |
| `XF86MonBrightnessUp` | 提高亮度 |
| `XF86MonBrightnessDown` | 降低亮度 |

## 音量與媒體鍵

| 快捷鍵 | 動作 |
|---|---|
| `XF86AudioMute` | 靜音 / 取消靜音 |
| `XF86AudioRaiseVolume` | 提高音量 |
| `XF86AudioLowerVolume` | 降低音量 |
| `XF86AudioPlay` | 播放 / 暫停 |
| `XF86AudioNext` | 下一首 |
| `XF86AudioPrev` | 上一首 |

## 其他

| 觸發 | 動作 |
|---|---|
| `Lid Switch` | 蓋上筆電螢幕時鎖定 |

## 備註

- 若之後把 `bar` 改成 `hyprpanel`，`SUPER + SHIFT + T` 會改為 `hyprpanel-toggle`，而不是 QuickSnip。
- `SUPER + 0` 目前沒有在 `home/system/hyprland/bindings.nix` 啟用；目前只產生 `1..9`。
