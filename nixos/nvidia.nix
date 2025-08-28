{ lib, pkgs, config, inputs, ... }:

let
  # 先匯入 nixos-unstable 的 pkgs，只拿來取得最新版 NVIDIA 原始碼
  unstablePkgs = import inputs."nvidia-src" { 
    system = pkgs.system; 
    config = {
      allowUnfree = true;
      nvidia.acceptLicense = true;
    };
  };

  # 580.x 版驅動在 unstable 的 derivation
  #upstreamDrv = unstablePkgs.linuxPackages_6_12.nvidia_x11;
  upstreamDrv = unstablePkgs.linuxPackages_latest.nvidiaPackages.latest;



  # 以目前 kernelPackages 為基礎，重新 build 與核心相容的驅動
  #nvidiaDriverChannel = config.boot.kernelPackages.nvidiaPackages.mkDriver {
    #version            = upstreamDrv.version;                  # 例：560.42.04
    #sha256_64bit       = upstreamDrv.src.outputHash;

    ##settingsSha256     = upstreamDrv.settings.src.outputHash;
    #persistencedSha256 = upstreamDrv.persistenced.src.outputHash;
    #sha256_32bit        = null;
  #};
in {
  # Load nvidia driver for Xorg and Wayland
  services.xserver.videoDrivers = [ "nvidia" "displayLink" ]; # or "nvidiaLegacy470 etc.

  boot.kernelParams = lib.optionals (lib.elem "nvidia" config.services.xserver.videoDrivers) [
    "nvidia-drm.modeset=1"
    "nvidia_drm.fbdev=1"
    "nvidia.NVreg_PreserveVideoMemoryAllocations=1"
  ];

  environment.variables = {
    # GBM_BACKEND = "nvidia-drm"; # If crash in firefox, remove this line
    LIBVA_DRIVER_NAME         = "nvidia"; # hardware acceleration
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    NVD_BACKEND               = "direct";
  };

  nixpkgs.config = {
    allowUnfree = true;
    nvidia.acceptLicense   = true;
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
      open                   = true;
      nvidiaSettings         = false;
      powerManagement.enable = true;  # May affect sleep/suspend
      modesetting.enable     = true;
      #package                = nvidiaDriverChannel;
      package                = upstreamDrv;
    };

    graphics = {
      enable = true;
      package = upstreamDrv;
      enable32Bit = true;
      extraPackages = with pkgs; [
        nvidia-vaapi-driver
        vaapiVdpau
        libvdpau-va-gl
        mesa
        egl-wayland
      ];
    };

    #opengl = {
      #enable          = true;
      #driSupport32Bit = true;
      ##package         = nvidiaDriverChannel;
      #package         = upstreamDrv;
      #extraPackages   = with pkgs; [
        #nvidia-vaapi-driver
        #vaapiVdpau
        #libvdpau-va-gl
        #mesa
        #egl-wayland
      #];
    #};
  };
  #environment.systemPackages = [
    #(import inputs."nvidia-src" { system = pkgs.system; }).nvidia-settings
  #];
}