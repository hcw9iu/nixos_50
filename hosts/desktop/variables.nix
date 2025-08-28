{ config, ... }: {
  imports = [ ../../nixos/variables-config.nix ];

  config.var = {
    hostname = "nixos";
    username = "hcw";
    configDirectory = "/home/" + config.var.username
      + "/.config/nixos"; # The path of the nixos configuration directory

    keyboardLayout = "us";

    location = "Taipei";
    timeZone = "Asia/Taipei";
    defaultLocale = "en_US.UTF-8";
    extraLocale = "zh_TW.UTF-8";

    git = {
      username = "hcw9iu";
      email = "hcw.chiu@gmail.com";
    };

    autoUpgrade = false;
    autoGarbageCollector = false;

    # Choose your theme variables here
    #theme = import ../../themes/var/pinky.nix;
    theme = import ../../themes/var/nixy.nix;
  };
}
