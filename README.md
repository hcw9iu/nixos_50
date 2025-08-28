# Change log
## Package log
[Attic](/docs/attic.md) - cache nix packages
## Main folder
> All settings are in `hosts/desktop` <br>
Except settings in `home` <br>
**Copy & replace** `hosts` to migrate

## System variables 
### Linux kernel version

1. `nixos/systemd-boot.nix` : 

    ```nix
    14: kernelPackage = 
    15:     pkgs.linuxPackages_6_12; 
    16:     #pkgs.linuxPackages_latest;
    ```
    *Latest (2025-1-25) kernel 6.13 conflicts nvidia driver 565.77 (beta)*

2. `home/programs/shell/zsh.nix` :

    ```nix
    59: sessionVariables = {
    60:  LD_LIBRARY_PATH = lib.concatStringsSep ":" [
    61:    "${pkgs.linuxPackages_6_12.nvidia_x11_production}/lib" 
    62:     # production(550.142), stable, latest, beta
    62:    "$LD_LIBRARY_PATH"
    63:  ];
    64: };
    ```
   *linuxPackage_6_12 instead of linuxPackage_latest*

### GPU driver version

1. `nixos/nvidia.nix` :

    ```nix
    3:  nvidiaDriverChannel =
    4:    config.boot.kernelPackages.nvidiaPackages.production;
    5:    # originally beta
    ```
    *Must consist with `zsh.nix`*

## Hyprland variables
### Multi-Monitor location

1. `home/system/hyprland/default.nix` :
    
    ```nix
    68: monitor = [
    69:     "DP-3,3440x1440@99.98,0x0,1"
    70:     "HDMI-A-2,1920x1080@60,780x-1080,1"
    71: ];
    ```
    *HDMI monitor relatively shift right 780px and up 1080px*

### Hyprpanel Avatar

1.  `home/system/hyprpanel/default.nix` :

    ```nix
    99: "menus.dashboard.powermenu.avatar.image" = \
    100:    "/home/${username}/.profile_picture.png";
    ```
    and in `hosts/desktop/home.nix` :

    ```nix
    110: file.".profile_picture.png" = { source = ./profile_picture.png; };
    ```

## Theme variable
### Mouse cursor
`themes/stylix/nixy.nix` :
```nix
32: cursor = {
33:   package = pkgs.bibata-cursors;
34:   name = "Bibata-Modern-Classic";
35:   size = 40;
36: };
```
*bibata is a cursor package*

### Terminal fetch
1. `themes/var/nixy.nix` :
    ```nix
    10: fetch = "nitch"; # "nerdfetch" | "neofetch" | "pfetch" | "nitch"
    ```

2. `home/programs/shell/zsh.nix` :
    ```nix
    initExtraFirst = ''
      bindkey -e
      ${if fetch == "neofetch" then
        pkgs.neofetch + "/bin/neofetch"
      else if fetch == "nerdfetch" then
        "nerdfetch"
      else if fetch == "pfetch" then
        "echo; ${pkgs.pfetch}/bin/pfetch"
      else if fetch == "nitch" then #added
        "nitch" #added
      else
        ""}
    ```