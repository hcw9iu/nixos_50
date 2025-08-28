{ pkgs, inputs, ... }: {
  imports = [ inputs.sops-nix.homeManagerModules.sops ];

  sops = {
    age.keyFile = "/home/hcw/.config/sops/age/keys.txt";
    defaultSopsFile = ./secrets.yaml;
    secrets = {
      #sshconfig = { path = "/home/hcw/.ssh/config"; };
      github-key = { path = "/home/hcw/.ssh/github"; };
      #gitlab-key = { path = "/home/hcw/.ssh/gitlab"; };
      #jack-key = { path = "/home/hcw/.ssh/jack"; };
      #pia = { path = "/home/hcw/.config/pia/pia.ovpn"; };
    };
  };

  home.file.".config/nixos/.sops.yaml".text = ''
    keys:
      - &primary age1ce68cdtrphwv2ec5jk79t5exzflfz2ly3nzscjnv9r9s9xqtr3uqvf9yxd
    creation_rules:
      - path_regex: hosts/desktop/secrets/secrets.yaml$
        key_groups:
          - age:
            - *primary
  '';

  systemd.user.services.mbsync.Unit.After = [ "sops-nix.service" ];
  home.packages = with pkgs; [ sops age ];

  wayland.windowManager.hyprland.settings.exec-once =
    [ "systemctl --user start sops-nix" ];
}
