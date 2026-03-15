# 啟用 Hyprlock 的 FIDO2 解鎖（NixOS）

本指南使用 PAM + `pam_u2f`，讓 Hyprlock 可以透過 FIDO2/U2F 硬體金鑰（例如 Ledger Stax 的 Security Key app）解鎖。

## 1) 準備硬體金鑰
- 確認硬體金鑰已切換為 FIDO2/U2F 模式（Ledger Stax 請使用 Security Key app）。

## 2) 註冊金鑰（建立對映檔）
用你的使用者執行：

```sh
mkdir -p ~/.config/Yubico
pamu2fcfg > ~/.config/Yubico/u2f_keys
```

如果要加入多把金鑰，改用 append：

```sh
pamu2fcfg >> ~/.config/Yubico/u2f_keys
```

## 3) 在 NixOS 設定 PAM
把以下內容加入（或合併到）你的 NixOS 設定：

```nix
{ config, pkgs, ... }:
{
  # 啟用 pam_u2f
  security.pam.u2f.enable = true;

  # 二擇一：
  # "sufficient" = 只要金鑰即可解鎖（密碼仍可用）
  # "required"   = 金鑰 + 密碼（雙因素）
  security.pam.u2f.control = "sufficient";

  # 確保 hyprlock 有 PAM 服務
  security.pam.services.hyprlock = {};
}
```

選配強化（若你的金鑰支援觸控）：

```nix
security.pam.u2f.settings = {
  # 要求使用者觸控
  cue = true;
  # 其他 pam_u2f 參數可在此加上
};
```

## 4) 重建並測試

```sh
sudo nixos-rebuild switch
```

鎖定畫面後，用金鑰解鎖。若設定 `control = "required"`，同時需要輸入密碼。

## 5) 復原方案
若被鎖在外面，可切到 TTY 或救援模式，暫時移除 PAM U2F 設定後再重建。

---

備註：
- Hyprlock 只透過 PAM 驗證；主題檔（例如 `home/system/hyprlock/default.nix`）不影響解鎖方式。
- 若想用 `pam_fido2`，需自行寫入 PAM 服務設定；使用 `security.pam.u2f.*` 是 NixOS 最簡單的方式。
