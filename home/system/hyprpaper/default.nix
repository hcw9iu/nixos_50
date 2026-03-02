# Hyprpaper is used to set the wallpaper on the system
{ config, lib, ... }: {
  # The wallpaper is set by stylix
  # Start hyprpaper from Hyprland exec-once to inherit session env.
  services.hyprpaper.enable = lib.mkForce false;

  # Force a raw config file to avoid parser quirks with generated key=value format.
  xdg.configFile."hypr/hyprpaper.conf" = {
    force = true;
    text = ''
      ipc = on
      splash = false
      splash_offset = 2
      wallpaper {
        monitor =
        path = ${toString config.stylix.image}
      }
    '';
  };

  # Prevent module from generating its own config content.
  services.hyprpaper.settings = lib.mkForce { };
}
