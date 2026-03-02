{ pkgs, inputs, ... }: {
  imports = [ inputs.sops-nix.homeManagerModules.sops ];

  sops = {
    age.keyFile = "/home/hcw/.config/sops/age/keys.txt";
    defaultSopsFile = ./secrets.yaml;
    secrets = {
      #sshconfig = { path = "/home/hcw/.ssh/config"; };
      #github-key = { path = "/home/hcw/.ssh/github"; };
      #gitlab-key = { path = "/home/hcw/.ssh/gitlab"; };
      #jack-key = { path = "/home/hcw/.ssh/jack"; };
      #pia = { path = "/home/hcw/.config/pia/pia.ovpn"; };
      "openai_api" = { path = "/home/hcw/.config/nix-ai-help/api-key"; };
    };
  };

  home.file.".config/nixos/.sops.yaml".text = ''
    keys:
      - &primary age1gaeck2j22zczhmqq3yx7u5gp0hdglgx8e63vce5u4cysxpv7cqgqxgnrp0
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
