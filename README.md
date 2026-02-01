# Installation Steps
1. Boot through `NixOS Live ISO` usb
2. Do proper disk segmentation. e.g. /root, /home/<user>
3. Clone this repo into Live ISO and install through it. `nixos install --flake <repo path>`
4. After reboot, must change owner to user in TTY entered by F2~F6 `sudo chown -R /home/<user> <user>`
5. Change user password. `passwd <user>`  
6. Rebuild to apply settings. `sudo nixos-rebuild switch --flake <path to this repo>`