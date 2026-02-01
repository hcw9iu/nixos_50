{ pkgs, ... }:
{
  programs.fcitx5 = {
    enable = true;
    addons = with pkgs; [
      fcitx5-chewing
      fcitx5-rime
      fcitx5-chinese-addons
      fcitx5-gtk
      #fcitx5-qt
    ];
  };

  # 配置工具還是需要手動安裝
  #home.packages = with pkgs; [
    #fcitx5-configtool
  #];
}