{ lib, pkgs, ... }: {
  imports = [ ./torch.nix ];
  home = {
    sessionVariables.PYTHONPATH_BASE = lib.concatStringsSep ":"
      (map (pkg: "${pkg}/lib/python3.10/site-packages") [
        #pkgs.python310Packages.pandas
        pkgs.python310Packages.numpy
        pkgs.python310Packages.torchWithCuda
        pkgs.python310Packages.typing-extensions
        pkgs.python310Packages.torchaudio
        pkgs.python310Packages.torchvision
        pkgs.python310Packages.onnxruntime
      ]); # + ":$PYTHONPATH";
  };
}
