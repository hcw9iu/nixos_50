{
  hardware.nvidia.prime = {
    offload = {
      enable = true;
      enableOffloadCmd = true;
    };

    # sync.enable = true;

    # CHANGEME: Change those values to match your hardware (if prime is imported)
    # check with lspci | grep -i vga
    amdgpuBusId =
      "PCI:122:0:0"; # Set this to the bus ID of your AMD GPU if you have one
    # intelBusId = "PCI:0:2:0"; # Set this to the bus ID of your Intel GPU if you have one
    nvidiaBusId =
      "PCI:1:0:0"; # Set this to the bus ID of your Nvidia GPU if you have one
  };
}
