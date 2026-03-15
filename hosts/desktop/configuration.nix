{ config, pkgs, ... }: {

  nixpkgs.config.allowUnfree = true;

  imports = [
    ../../nixos/nvidia.nix # CHANGEME: Remove this line if you don't have an Nvidia GPU
    #../../nixos/prime.nix # for multiple GPUs (Nvidia + others) 

    #../../nixos/attic.nix
    ../../nixos/audio.nix
    ../../nixos/auto-upgrade.nix
    ../../nixos/bluetooth.nix
    ../../nixos/fonts.nix
    ../../nixos/home-manager.nix
    ../../nixos/network-manager.nix
    ../../nixos/nix.nix
    ../../nixos/systemd-boot.nix
    ../../nixos/timezone.nix
    #../../nixos/sddm.nix
    #../../nixos/hyprland.nix
    ../../nixos/tuigreet.nix
    ../../nixos/users.nix
    ../../nixos/utils.nix
    ../../nixos/xdg-portal.nix
    ../../nixos/variables-config.nix
    ../../nixos/docker.nix
    #../../nixos/pia.nix

    #../../nixos/openrgb.nix
    ../../nixos/steam.nix
    #../../nixos/nixai.nix

    ../../nixos/pam-u2f.nix


    # Choose your theme here
    ../../themes/stylix/nixy.nix

    ./hardware-configuration.nix
    ./variables.nix
  ];

  home-manager.users."${config.var.username}" = import ./home.nix;

  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5.addons = with pkgs; [ fcitx5-chewing fcitx5-gtk ];
    fcitx5.settings.globalOptions = {
      Behavior = {
        EnabledAddons = "chewing";
      };
    };
    fcitx5.settings.inputMethod = {
      "Groups/0" = {
        Name = "Default";
        "Default Layout" = "us";
        DefaultIM = "keyboard-us";
      };
      "Groups/0/Items/0" = {
        Name = "keyboard-us";
        Layout = "";
      };
      "Groups/0/Items/1" = {
        Name = "chewing";
        Layout = "";
      };
      "GroupOrder" = { "0" = "Default"; };
    };
  };

  environment.sessionVariables = {
    FCITX_DATA_DIRS = "${config.i18n.inputMethod.package}/share";
  };

  # Don't touch this
  system.stateVersion = "24.05";
}
