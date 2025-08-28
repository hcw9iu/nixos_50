{ lib, pkgs, config, ... }: {
  #import = [ ./base/default.nix ./audio/default.nix ];
  home = {
    sessionVariables.PYTHONPATH = lib.concatStringsSep ":" [
      config.home.sessionVariables.PYTHONPATH_BASE
      config.home.sessionVariables.PYTHONPATH_AUDIO
      "$PYTHONPATH"
    ];
  };
}
