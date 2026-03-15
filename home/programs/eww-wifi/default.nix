{ pkgs, config, ... }:
{
  home.packages = [ pkgs.eww ];

  xdg.configFile."eww/qs-wifi/eww.yuck".source = ./files/eww.yuck;
  xdg.configFile."eww/qs-wifi/eww.scss".source = ./files/eww.scss;
  xdg.configFile."eww/qs-wifi/scripts/sys_info.sh" = {
    source = ./files/sys_info.sh;
    executable = true;
  };

  xdg.configFile."hypr/scripts/eww_wifi.sh" = {
    source = ./files/eww_wifi.sh;
    executable = true;
  };
}
