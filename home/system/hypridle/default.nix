# Hypridle is a daemon that listens for user activity and runs commands when the user is idle.
{ pkgs, ... }: {
  services.hypridle = {
    enable = true;
    settings = {

      general = {
        ignore_dbus_inhibit = false;
        lock_cmd = "pidof hyprlock || ~/.config/hypr/scripts/update_lock_wallpaper.sh; ~/.config/hypr/sakoora.hyprlock/hyprlock-run/panels && ${pkgs.hyprlock}/bin/hyprlock --grace 0";
        before_sleep_cmd = "loginctl lock-session";
        after_sleep_cmd = "hyprctl dispatch dpms on";
      };

      listener = [
        {
          timeout = 600;
          on-timeout = "pidof hyprlock || ~/.config/hypr/scripts/update_lock_wallpaper.sh; ~/.config/hypr/sakoora.hyprlock/hyprlock-run/panels && ${pkgs.hyprlock}/bin/hyprlock --grace 0";
        }

        {
          timeout = 660;
          on-timeout = "systemctl suspend";
        }
      ];
    };
  };
}
