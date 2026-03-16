{ pkgs, config, inputs, ... }:
let
  pkgsCodex = import inputs.nixpkgsCodex {
    system = pkgs.system;
    config.allowUnfree = true;
  };
in {
  imports = [
    ./variables.nix

    # Programs
    ../../home/programs/kitty
    ../../home/programs/nvim
    #../../home/programs/qutebrowser #not useful, function ok
    ../../home/programs/shell
    ../../home/programs/fetch
    ../../home/programs/git
    #../../home/programs/spicetify
    #../../home/programs/nextcloud
    ../../home/programs/yazi
    ../../home/programs/markdown
    ../../home/programs/thunar
    ../../home/programs/lazygit
    #../../home/programs/nh
    ../../home/programs/matuwall
    ../../home/programs/quickshell-wallpaper
    ../../home/programs/zen
    #../../home/programs/fcitx5
    #../../home/programs/server-page

    # Scripts
    ../../home/scripts # All scripts

    # System (Desktop environment like stuff)
    ../../home/system/hyprland
    ../../home/system/hypridle
    ../../home/system/hyprlock
    ../../home/system/hyprpanel
    ../../home/system/hyprpaper
    #../../home/system/gtk
    ../../home/system/wofi
    ../../home/system/batsignal
    ../../home/system/zathura
    ../../home/system/mime
    ../../home/system/udiskie
    ../../home/system/clipman
    ../../home/system/tofi
    ../../home/system/wlogout

    # Python Packages
    #../../home/python/base # include pytorch
    #../../home/python/audio
    #../../home/python # Handle PYTHONPATH. Put last

    # Github key
    ./secrets
  ];

  home = {
    inherit (config.var) username;
    homeDirectory = "/home/" + config.var.username;
    sessionPath = [ "${config.home.homeDirectory}/.local/bin" ];

    packages = with pkgs;
      [
        # Apps
        discord # Chat
        bitwarden # Password manager
        vlc # Video player
        #blanket # White-noise app
        signal-desktop

        #rgb
        openrgb

        # Dev
        go
        nodejs
        python310
        jq
        figlet
        just
        uv
        gh
        gh-dash
        git

        # Rust 
        #rustup 
        rustc
        cargo

        # Utils
        appimage-run
        zip
        unzip
        optipng
        pfetch
        pandoc
        btop
        nitch

        # Just cool
        peaclock
        cbonsai
        pipes
        cmatrix

        # Backup
        firefox
        vscode

        aider-chat

        # Communication
        session-desktop

      ] ++ [
        inputs.codex-nix.packages.${pkgs.system}.codex
      ];

    # Import my profile picture, used by the hyprpanel dashboard
    file.".profile_picture.png" = { source = ./profile_picture.png; };

    # Don't touch this
    stateVersion = "24.05";
  };

  programs.home-manager.enable = true;
}
