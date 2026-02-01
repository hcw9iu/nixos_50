   # /home/hcw/.config/nixos/nixos/openrgb.nix
   { pkgs, ... }: {
     environment.systemPackages = [ pkgs.openrgb ];

     # 安裝官方提供的 udev 規則
     services.udev.packages = [ pkgs.openrgb ];

     # 若你的主機板走 I²C，順便開啟
     hardware.i2c.enable = true;
     boot.kernelModules = [
       "i2c-dev"
       #"i2c-i801" # 或 i2c-piix4、i2c-nct6775… 視晶片而定
       "i2c-piix4"
       "nct6775"    
     ];
     users.users.<user>.extraGroups = [ "plugdev" "i2c" ];
   }