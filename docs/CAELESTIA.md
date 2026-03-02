# 導入 Caelestia（dots/shell）將取代與新增的內容

以下內容假設「完整導入 Caelestia shell 生態」，並以目前此 repo 的 Hyprland UI 堆疊為基準；實際取代項目會依你選的導入範圍而不同。

## 可能被取代 / 停用
- Hyprpanel 作為主要面板/小工具（若改用 Caelestia Shell 的 Quickshell UI）。
- 既有 Hyprpanel 的切換腳本與快捷鍵（`home/system/hyprpanel`、`home/scripts/hyprpanel`、相關綁定）。
- 任何既有的 AGS/面板類 UI 啟動方式（若與 Caelestia Shell 重疊）。

## 會新增 / 安裝
- Caelestia Shell（Quickshell UI）與其 Home Manager 模組（`programs.caelestia`）。
- Caelestia CLI（用於管理/更新 Caelestia 生態，若一併啟用）。
- Caelestia 相關設定檔與資源（放在 `home/` 對應模組或 `xdg.configFile`）。

## 可能需要調整
- Hyprland `exec-once` 或 systemd user 服務啟動方式（改為啟動 Caelestia Shell）。
- 既有 Hyprland 鍵綁定，避免與 Caelestia 的快捷鍵衝突。

## 導入時需要修改的檔案（依目前 repo 結構）
- `flake.nix`：新增 Caelestia flake input，接上對應的 Home Manager 模組/overlay。
- `hosts/desktop/home.nix`：移除或改成選配 `home/system/hyprpanel`，並加入 Caelestia 模組。
- `home/system/hyprpanel/default.nix`：停用或改成選配，避免 UI 重疊。
- `home/scripts/default.nix`：移除或改成選配 `./hyprpanel` 腳本集合。
- `home/scripts/hyprpanel/default.nix`：Hyprpanel 的切換/重載/顯示/隱藏腳本可移除。
- `home/system/hyprland/bindings.nix`：移除或改寫 `hyprpanel-*` 綁定。
- `home/system/hyprland/default.nix`：在 `exec-once` 或 systemd user 服務中啟動 Caelestia Shell。
- 可能新增 `home/system/caelestia/default.nix`：集中 Caelestia 設定與 `programs.caelestia`。
- 可能新增 Caelestia 設定檔：放在 `home/` 或 `xdg.configFile` 內對應路徑。

## 優點
- UI/小工具整合度高：以 Quickshell 為核心，提供更一致的桌面體驗。
- 較少拼裝：可減少多個面板/小工具之間的碎片化整合成本。
- 主題一致性：外觀與互動風格更統一，視覺風格更完整。
- 可維護性提升：集中在 Caelestia 生態更新，較少分散管理。

## 缺點
- 侵入性高：可能需要移除或停用既有 Hyprpanel/AGS 相關配置與腳本。
- 風險與相容性：與現有快捷鍵、啟動流程、腳本可能衝突。
- 學習成本：需要熟悉 Caelestia 的配置方式與更新流程。
- 綁定生態：一旦深度採用，回退到原本 UI 堆疊成本較高。
