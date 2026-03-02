# Hyprland 0.46 -> 0.54 破壞性升級重點

這個 repo 目前使用 Hyprland 0.46。以下是從 0.46 升到 0.54 時必須處理的破壞性或高風險變更。

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

## Nixpkgs 來源（升級前置）

- 目前本 repo 的 nixpkgs 來源：  
  - `nixpkgs.url = "github:nixos/nixpkgs/dc460ec76cbff0e66e269457d7b728432263166c"`（見 `flake.nix`）  
  - `nixpkgsCodex.url = "github:nixos/nixpkgs/nixos-25.11"`（見 `flake.nix`）  
- 必須使用「包含 Hyprland 0.54」的 nixpkgs 來源，否則無法取得對應版本。  
- 建議切換到較新的 nixpkgs（例如更新的 `nixos-25.11` 或 `nixos-unstable`），並固定 revision 以便回滾。  
- 若仍要使用舊版 nixpkgs，請改走 `inputs.hyprland` 的 flake 並確保其依賴都能被目前的 nixpkgs 成功建置。

## Hyprnix 完整整合（取代 `inputs.hyprland`）

- 目標：用 Hyprnix 提供的模組與套件來源，取代目前 `inputs.hyprland`（你的 fork），統一由 Hyprnix 管理 Hyprland 及其 Nix 整合。
- 需要在 `flake.nix` 新增 `hyprnix` input，並移除或停用 `inputs.hyprland`。
- `nixos/hyprland.nix` 與 `home/system/hyprland/default.nix` 內引用 `inputs.hyprland.packages...` 的地方，必須改為 Hyprnix 提供的對應輸出。
- 若仍需使用 Hyprland fork，則不適合「完整取代」，需改為部分導入或延後此步驟。
- 完整整合前，先確認 Hyprnix 版本與 Nixpkgs 來源是否相容（避免評估階段就無法建置）。
- hyprland source: inputs.hyprland.url = "github:hyprwm/Hyprland?ref=v0.54.0";

## 必改項目（會壞）

1) 0.53 開始，Window rules 語法改版  
   - 所有 `windowrule` / `windowrulev2` 必須改寫為新語法。
   - 目前設定在 `home/system/hyprland/default.nix` 有 `windowrulev2`。

2) 0.53 移除 `misc:new_window_takes_over_fullscreen`  
   - 改用 `misc:on_focus_under_fullscreen`，必要時搭配 `master:inherit_fullscreen`。
   - 目前設定在 `home/system/hyprland/default.nix`：`new_window_takes_over_fullscreen = 2;`。

3) 0.53 Hyprland 啟動指令改名  
   - Display manager 內的 `Hyprland` 改成 `start-hyprland`。
   - 目前設定在 `nixos/tuigreet.nix` 使用 `--cmd Hyprland`。

4) 0.50 移除 legacy renderer（強制需要 GLES 3.0）  
   - 沒有 GLES 3.0 的顯卡/驅動會直接無法啟動。
   - 升級前需確認 GPU/driver 支援。

## 行為改變（高風險）

5) 0.54 起 `hyprscrolling` 變成內建 layout  
   - 若使用外掛版 `hyprscrolling`，升級後需移除外掛並改用內建。
   - 外掛版在 0.54+ 可能衝突或無法載入。

6) 0.54 移除 `togglesplit` / `swapsplit`  
   - 如有綁定，需改用 `layoutmsg` 等效指令。
   - 目前設定未見這兩個綁定，但之後不要再用。

## 系統層面可能衝突（需逐項檢查）

1) Greetd/tuigreet 啟動指令  
   - `nixos/tuigreet.nix` 仍使用 `--cmd Hyprland`，0.53+ 需改 `start-hyprland`。
   - 否則登入後可能黑畫面或無法啟動。

2) xdg-desktop-portal-hyprland 版本一致性  
   - `nixos/hyprland.nix` 直接使用 `inputs.hyprland.packages...xdg-desktop-portal-hyprland`。
   - 升級 Hyprland 時必須一起升級 portal，否則可能出現螢幕分享、文件選擇、桌面入口異常。

3) Hyprland 插件 ABI 相容性  
   - 任何外掛（如 hyprspace、未來若加入 hyprscrolling）都要用 `follows = "hyprland"` 同步版本。
   - 否則會有載入失敗或 compositor 當機風險。

4) Hyprpanel / Hyprpolkitagent / 其他 Hypr* 套件  
   - 這些在 `flake.nix` 有獨立 pins（例如 Hyprpanel 指定 commit）。
   - Hyprland 大版本升級後可能產生 API 不相容，需要同步更新或回退。

5) 顯示/渲染相關環境變數  
   - 目前 Hyprland 設定中強制 `WLR_BACKEND=vulkan`、`WLR_RENDERER=vulkan`、`WLR_DRM_NO_ATOMIC=1`。  
   - 升級後若出現黑畫面或效能異常，需先檢查這些變數是否仍適用。

## 本次已套用的修改（已完成）

- `nixos/tuigreet.nix`  
  - 已將 `--cmd Hyprland` 註解，改為 `--cmd start-hyprland`。
- `home/system/hyprland/default.nix`  
  - 已將 `misc:new_window_takes_over_fullscreen` 註解，改為 `misc:on_focus_under_fullscreen = 2;`。  
  - 已將 `windowrulev2` 註解，改為新版 `windowrule`：`match:tag modal`。

- 變更點

- nixos/tuigreet.nix：把 --cmd Hyprland 註解掉，改為 --cmd start-
    hyprland
- home/system/hyprland/default.nix：把
    misc:new_window_takes_over_fullscreen 註解掉，新增
    misc:on_focus_under_fullscreen = 2;
  - home/system/hyprland/default.nix：把 windowrulev2 註解掉，改用新版
    windowrule 語法（match:tag modal）
  - home/system/hyprland/default.nix：移除 general:border_part_of_window，改放到 decoration:border_part_of_window
  - home/system/hyprland/default.nix：gestures:workspace_swipe 改為新版 gesture 設定
  - home/system/hyprland/default.nix：layerrule 的 noanim 改為新版 no_anim + match:namespace 語法
