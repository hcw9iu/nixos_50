{ lib, pkgs, ... }: {
  imports = [ ./audio.nix ];
  home = {
    sessionVariables.PYTHONPATH_AUDIO = lib.concatStringsSep ":"
      (map (pkg: "${pkg}/lib/python3.10/site-packages") [
        #Librosa Prep
        pkgs.python310Packages.librosa
        pkgs.python310Packages.lazy-loader
        #Soundfile Prep
        pkgs.python310Packages.soundfile
        pkgs.python310Packages.cffi
        #Pandas Prep
        pkgs.python310Packages.pandas
        pkgs.python310Packages.dateutil
        pkgs.python310Packages.pytz
        pkgs.python310Packages.six
        #Scipy
        pkgs.python310Packages.scipy
        #tqdm
        pkgs.python310Packages.tqdm
        #Deepfilter
        pkgs.python310Packages.h5py
        pkgs.python310Packages.loguru
      ]); # + ":$PYTHONPATH";
  };
}
