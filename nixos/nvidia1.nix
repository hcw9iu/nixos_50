{ lib, pkgs, config, ... }:
let
  nvidiaDriverChannel =
    config.boot.kernelPackages.nvidiaPackages.beta; # stable, latest, beta, production, etc.
    #config.boot.kernelPackages.nvidiaPackages.mkDriver {
      #version = "565.77"; #stable
      #sha256_64bit       = "0z0lncf3q4ndf16k928vpjrzvc9xgg8h494qcvbk9kvbqi1afyha";
      #sha256_32bit       = "0z0lncf3q4ndf16k928vpjrzvc9xgg8h494qcvbk9kvbqi1afyha";
      ##settingsSha256     = "0jds62i0pymn1riklkfdhq1jwzip0brhv0qz5kzjqfg5fa7ssism";
      #persistencedSha256 = "031b583hndq5c9c93j6py6yzxhkf08yz9ac16iywf3vx9w5y6w62";
    #};
    #nvidiaDriverChannel = pkgs.linuxPackages_latest.nvidiaPackages.latest;
in {
  # Load nvidia driver for Xorg and Wayland
  #boot.kernelPackages = pkgs.linuxPackages_latest;
   
  services.xserver.videoDrivers =
    [ "nvidia" "displayLink" ]; # or "nvidiaLegacy470 etc.
  boot.kernelParams =
    lib.optionals (lib.elem "nvidia" config.services.xserver.videoDrivers) [
      "nvidia-drm.modeset=1"
      "nvidia_drm.fbdev=1"
      "nvidia.NVreg_PreserveVideoMemoryAllocations=1"
    ];
  environment.variables = {
    # GBM_BACKEND = "nvidia-drm"; # If crash in firefox, remove this line
    LIBVA_DRIVER_NAME = "nvidia"; # hardware acceleration
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    NVD_BACKEND = "direct";
  };
  nixpkgs.config = {
    nvidia.acceptLicense = true;
    allowUnfreePredicate = pkg:
      builtins.elem (lib.getName pkg) [
        "cudatoolkit"
        "nvidia-persistenced"
        "nvidia-settings"
        "nvidia-x11"
      ];
  };
  hardware = {
    nvidia = {
      open = true;
      nvidiaSettings = false;
      powerManagement.enable =
        true; # This can cause sleep/suspend to fail and saves entire VRAM to /tmp/
      modesetting.enable = true;
      package = nvidiaDriverChannel;
    };
    #graphics = {
      #enable = true;
      #package = nvidiaDriverChannel;
      #enable32Bit = true;
      #extraPackages = with pkgs; [
        #nvidia-vaapi-driver
        #vaapiVdpau
        #libvdpau-va-gl
        #mesa
        #egl-wayland
      #];
    #};
    opengl = {
      enable = true;
      driSupport32Bit = true;
      package = nvidiaDriverChannel;
      extraPackages = with pkgs; [
        nvidia-vaapi-driver
        vaapiVdpau
        libvdpau-va-gl
        mesa
        egl-wayland
      ];
    };
  };
}
