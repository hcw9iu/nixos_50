{
  pkgs,
  ...
}: {
  services.displayManager.sddm = {
    enable         = true;          # 開啟 SDDM
    package = pkgs.libsForQt5.sddm;
    #wayland.enable = true;          # 同時支援 Wayland
    #theme          = "sugar-candy";
  };

  #environment.systemPackages = with pkgs; [
    #pkgs."sddm-sugar-candy"             # 安裝主題檔
  #];
}