{ pkgs, ... }:
let pythonPackages = pkgs.python310Packages;
in {
  home = {
    packages = with pythonPackages; [
      soundfile
      librosa
      pandas
      scipy
      tqdm
      h5py #Deepfilter
      loguru #Deepfilter 
    ];
  };
}
