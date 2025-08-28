{ pkgs, ... }:
let pythonPackages = pkgs.python310Packages;
in {
  home = {
    packages = with pythonPackages; [
      numpy
      torchWithCuda
      typing-extensions
      torchaudio
      torchvision
      onnxruntime
    ];
  };
}
