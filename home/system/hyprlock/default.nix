# Hyprlock is a lockscreen for Hyprland
{ pkgs, lib, ... }:
let
  sakooraRoot = ./sakoora;
  sakooraCfg = "${sakooraRoot}";
  sakooraFonts = "${sakooraRoot}/fonts";

  sizesConf = ''
    #################
    ### UNIVERSAL ###
    #################
    $body_font = 20
    $huge_font = 100
    $heading_font = 50
    $large_font = 30
    $small_font = 15

    ################
    ### TOP LEFT ###
    ################
    $top_left_offset = -540, 140
    $pw_box_offset = -540, 480
    $un_box_offset = -540, 600
    $pw_text_offset = 560, 540
    $un_text_offset = 560, 660
    $login_text_offset = -540, 740
    $hostname_text_offset = -540, 840
    $un_value_offset = 560, 630
    $input_field_offset = 540, 480
    $top_left_size = 480
    $container_box_size = 400, 100
    $input_field_size = 400, 80

    ###################
    ### BOTTOM LEFT ###
    ###################
    $bottom_left_offset = -540, -260
    $time_text_offset = -540, -720
    $uptime_ltext_offset = 620, 200
    $uptime_rtext_offset = -1700, 200
    $bottom_left_size = 240

    #############
    ### RIGHT ###
    #############
    $right_offset = -20, 0
    $right_bottom_box_offset = -20, 60
    $network_box_offset = -130, 320
    $bluetooth_box_offset = 90, 320
    $power_box_offset = -20, 100
    $image_offset = -20, 800
    $media_symbol_offset = -20, -520
    $network_symbol_offset = -130, 380
    $bluetooth_symbol_offset = 90, 380
    $day_value_offset = -20, 680
    $date_value_offset = -20, 640
    $media_content_value_offset = -20, -560
    $media_player_value_offset = -20, -590
    $stock_box_offset = 500, 0
    $stock_box_size = $top_left_size
    $stock_nvda_box_offset = 500, 175
    $stock_btc_box_offset = 500, 105
    $stock_tsm_box_offset = 500, 35
    $stock_mu_box_offset = 500, -35
    $stock_qqq_box_offset = 500, -105
    $stock_xau_box_offset = 500, -175
    $stock_inner_box_size = 360, 60
    $nvda_text_offset = 500, 175
    $btc_text_offset = 500, 105
    $tsm_text_offset = 500, 35
    $mu_text_offset = 500, -35
    $qqq_text_offset = 500, -105
    $xau_text_offset = 500, -175
    $network_value_offset = -130, 350
    $bluetooth_value_offset = 90, 350
    $power_status_value_offset = -20, 140
    $power_percent_value_offset = -20, 160
    $power_indicator_value_offset = -20, 220
    $right_size = 480
    $right_bottom_box_size = 480, 540
    $power_box_size = 400, 180
    $connection_box_size = 180, 120
    $image_size = 160
  '';

  sizesSh = ''
    initial_cutout_offset=800+40
    top_left_offset=0+140
    bottom_left_offset=0+580
    right_offset=520+0
    initial_cutout_size=1000x960
    top_left_size=480x480
    bottom_left_size=480x240
    right_size=480x960
  '';
in {
  programs.hyprlock = {
    enable = true;
    settings = {
      background = lib.mkForce [
        {
          monitor = "DP-3";
          path = "~/.cache/hyprlock-cache/wallpaper.png";
          blur_passes = 3;
          blur_size = 3;
        }
        {
          monitor = "HDMI-A-2";
          path = "~/.cache/hyprlock-cache/wallpaper.png";
          blur_passes = 3;
          blur_size = 3;
        }
      ];
    };
    extraConfig = builtins.readFile "${sakooraRoot}/hyprlock.conf";
  };

  home.packages = with pkgs; [
    bluez
    curl
    imagemagick
    networkmanager
    playerctl
    grim
  ];

  home.file = {
    ".local/share/fonts/ttf/FiraCodeNerdFontMono-Regular.ttf".source =
      "${sakooraFonts}/FiraCodeNerdFontMono-Regular.ttf";
    ".local/share/fonts/ttf/JosefinSans-Italic-VariableFont_wght.ttf".source =
      "${sakooraFonts}/JosefinSans-Italic-VariableFont_wght.ttf";
    ".local/share/fonts/ttf/JosefinSans-VariableFont_wght.ttf".source =
      "${sakooraFonts}/JosefinSans-VariableFont_wght.ttf";
  };

  xdg.configFile = {
    "hypr/sakoora.hyprlock/colors-hyprlock.conf".source =
      "${sakooraCfg}/colors-hyprlock.conf";
    "hypr/sakoora.hyprlock/colors-hyprlock.sh".source =
      "${sakooraCfg}/colors-hyprlock.sh";
    "hypr/sakoora.hyprlock/sizes-hyprlock.conf".text = sizesConf;
    "hypr/sakoora.hyprlock/sizes-hyprlock.sh".text = sizesSh;
    "hypr/sakoora.hyprlock/profile.png".source = builtins.path {
      path = ../../../hosts/desktop/profile_picture_square.png;
    };
    "hypr/sakoora.hyprlock/hyprlock-run/bluetooth" = {
      source = "${sakooraCfg}/hyprlock-run/bluetooth";
      executable = true;
    };
    "hypr/sakoora.hyprlock/hyprlock-run/network" = {
      source = "${sakooraCfg}/hyprlock-run/network";
      executable = true;
    };
    "hypr/sakoora.hyprlock/hyprlock-run/panels" = {
      source = "${sakooraCfg}/hyprlock-run/panels";
      executable = true;
    };
    "hypr/sakoora.hyprlock/hyprlock-run/player" = {
      source = "${sakooraCfg}/hyprlock-run/player";
      executable = true;
    };
    "hypr/sakoora.hyprlock/hyprlock-run/power" = {
      source = "${sakooraCfg}/hyprlock-run/power";
      executable = true;
    };
    "hypr/sakoora.hyprlock/hyprlock-run/stock" = {
      source = "${sakooraCfg}/hyprlock-run/stock";
      executable = true;
    };
  };
}
