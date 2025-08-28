{ config, pkgs, inputs, ... }: 
let
  secret = pkgs.lib.fileContents "${inputs.atticConf}/private.base64";
  env = toString "${inputs.atticConf}/environment.env";
in {
  services.atticd = {
    enable = true;
    #user = "hcw";
    #group = "users";
    environmentFile = env;
    settings = {
      listen = "[::]:8080";
      jwt.signing = { 
        token-rs256-secret-base64 = secret;
      };
      storage = {
        type = "local";
        path = "/BD/cache/storage";
      };
      chunking = {
        nar-size-threshold = 64 * 1024; # 64 KiB
        min-size = 16 * 1024; # 16 KiB
        avg-size = 64 * 1024; # 64 KiB
        max-size = 256 * 1024; # 256 KiB
      };
    };
  };

  nix.settings = {
    trusted-users = [ "hcw" ];
  };
}
