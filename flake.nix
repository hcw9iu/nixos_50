{
  description = ''
    NixOS config by hcw
  '';
  nixConfig.license = "BSD-3-Clause";

  inputs = {
    #nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    #nixpkgs-24_05.url = "github:nixos/nixpkgs/nixos-24.05";
    #nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11"; 
    nixpkgs.url = "github:nixos/nixpkgs/dc460ec76cbff0e66e269457d7b728432263166c"; 
    nixos-hardware.url = "github:NixOS/nixos-hardware/master"; 
    nur.url = "github:nix-community/NUR";
    home-manager = {
      #url = "github:nix-community/home-manager/release-24.11"; 
      url = "github:nix-community/home-manager/daf04c5950b676f47a794300657f1d3d14c1a120";
      #ref = "daf04c5950b676f47a794300657f1d3d14c1a120";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixvim = {
      #url = "github:nix-community/nixvim/5fda6e093da13f37c63a5577888a668c38f30dc7"; 
      url = "github:nix-community/nixvim/11a80c1a80b16016ad03e703d1c9dea07f495cb7";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nvidia-src = {
      url = "github:nixos/nixpkgs/nixos-unstable";
      flake = false;
    };

    kernel-src = {
      url = "github:nixos/nixpkgs/nixos-unstable";
      flake = false;
    };

    #hyprspace = { url = "github:KZDKM/Hyprspace"; }; # fork
    #hyprland.url = "git+https://github.com/hyprwm/Hyprland?submodules=1"; # fork
    #hyprpolkitagent.url = "github:hyprwm/hyprpolkitagent"; # fork
    #hyprpanel.url = "github:Jas-SinghFSU/HyprPanel"; # fork
    #stylix.url = "github:danth/stylix/release-24.05"; # fork

    # atticd
    #attic = {
      #url = "github:zhaofengli/attic";
      #inputs.nixpkgs.follows = "nixpkgs";
    #};


    # ANCHORED COMMIT
    sops-nix = {
      url = "github:hcw9iu/sops-nix"; # fork
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hyprspace = { 
      #type = "git";
      #url = "git+ssh://git@github.com/hcw9iu/Hyprspace"; 
      url = "github:hcw9iu/Hyprspace"; 
      #ref = "main";
      }; 
    #hyprland = {
      #type = "git";
      #url = "git+ssh://git@github.com/hcw9iu/Hyprland";
      #submodules = true;
      #ref = "main";
      #allRefs = true;
    #};
    hyprland.url = "github:hcw9iu/Hyprland?submodules=1";
    hyprpolkitagent = {
      #type = "git";
      #url = "git+ssh://git@github.com/hcw9iu/hyprpolkitagent";
      url = "github:hcw9iu/hyprpolkitagent";
      #ref = "main";
      #allRefs = true;
    };
    hyprpanel = {
      #type = "git";
      #url = "git+ssh://git@github.com/hcw9iu/HyprPanel";
      url = "github:hcw9iu/Hyprpanel/10ac1fbf27e6a06329ef4279846a4aaadf7e332b";
      #ref = "main"; 
      #rev = "10ac1fbf27e6a06329ef4279846a4aaadf7e332b";
      #allRefs = true;
    };
    stylix.url = "github:hcw9iu/stylix"; 

    apple-fonts.url = "github:Lyndeno/apple-fonts.nix"; 
  
    zen-browser.url =
      "git+https://git.sr.ht/~canasta/zen-browser-flake/"; 
    
    wallpapers = {
      url = "github:anotherhadi/nixy-wallpapers"; # overwrite
      flake = false;
    };
    #cursor.url = "github:hcw9iu/cursor-flake/main?ssh=yes"; # overwrite, private repo
    #cursor = {
      #type = "git";
      #url = "git+ssh://git@github.com/hcw9iu/cursor-flake";
      #ref = "main";
      #allRefs = true;
    #};
    #atticConf = {
      #url = "path:/BD/cache/config";
      #flake = false;
    #};
  };

  outputs = inputs@{ nixpkgs, ... }: {
    nixosConfigurations = {
      nixos = # CHANGEME: This should match the 'hostname' in your variables.nix file
        nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          #specialArgs = { inherit inputs; }; # for attic
          modules = [
            {
              nixpkgs.overlays = [ 
                inputs.hyprpanel.overlay 
                inputs.nur.overlays.default
                #inputs.attic.overlays.default # for attic 
                # 引入 570up open-kernel NVIDIA 驅動
                #(final: prev:
                  #let
                    #up = import inputs."nvidia-src" { system = prev.system; };
                  #in {
                    #nvidia-open = up.linuxPackages_latest.nvidiaPackages.latest.open;
                  #})
                  (final: prev:
                    let
                      kpkgs = import inputs."kernel-src" { system = prev.system; };
                    in {
                      linuxPackages_6_16 = kpkgs.linuxPackages_latest;   # 目前 latest = 6.16.x
                    })
              ];
              _module.args = { inherit inputs; };
            }  
            #({ pkgs, inputs, ... }: {
              #environment.systemPackages = [ 
                ##pkgs.attic 
                #inputs.attic.packages.${pkgs.system}.attic # for attic
              #];
            #})
            #({ pkgs, ... }: {
              #environment.systemPackages = [
              #cursor.packages.${pkgs.system}.default
              #];
              ##boot.kernelPackages = pkgs.linuxPackages_6_12;
            #})
            inputs.home-manager.nixosModules.home-manager
            inputs.stylix.nixosModules.stylix
            #inputs.pia.nixosModules."x86_64-linux".default
            ./hosts/desktop/configuration.nix # CHANGEME: change the path to match your host folder
          ];
        };
    };
  };
}
