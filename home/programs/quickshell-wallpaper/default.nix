{ pkgs, lib, inputs, config, ... }:
let
  pkgsQs = import inputs.nixpkgsCodex {
    system = pkgs.system;
    config.allowUnfree = true;
  };

  quickshellDrv =
    if builtins.hasAttr "quickshell" pkgsQs then pkgsQs.quickshell
    else if builtins.hasAttr "qt6Packages" pkgsQs
      && builtins.hasAttr "quickshell" pkgsQs.qt6Packages then
      pkgsQs.qt6Packages.quickshell
    else
      lib.throwIfNot true "quickshell not found in nixpkgsCodex";

in {
  home.packages = with pkgs; [
    quickshellDrv
    imagemagick
    ffmpeg
    swww
  ];

  xdg.configFile = lib.mkMerge [
    {
      "hypr/scripts/update_lock_wallpaper.sh" = {
        source = ./files/update_lock_wallpaper.sh;
        executable = true;
      };
    }
    (lib.mkIf (config.var.bar != "topbar") {
      "hypr/scripts/qs_manager.sh" = {
        source = ./files/qs_manager.sh;
        executable = true;
      };

      "hypr/scripts/quickshell".source = ./files/quickshell;
    })
  ];
}
