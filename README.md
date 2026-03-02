# NixOS Configuration
Personal NixOS + Home Manager configuration with Hyprland as the primary Wayland compositor.

## Quick Install
1. Boot through `NixOS Live ISO` usb
2. Do proper disk segmentation (e.g. `/root`, `/home/<user>`)
3. Clone this repo in Live ISO and install: `nixos install --flake <repo path>#<host>`
4. After reboot, fix home ownership in TTY (F2~F6): `sudo chown -R <user>:<user> /home/<user>`
5. Change user password: `passwd <user>`
6. Rebuild to apply settings: `sudo nixos-rebuild switch --flake <path to this repo>#<host>`

## Structure
- `flake.nix`: inputs, outputs, and top-level wiring
- `hosts/`: host-specific NixOS configs
- `nixos/`: shared NixOS modules
- `home/`: Home Manager modules and user configs
- `themes/`: theme assets and overrides
- `docs/`: additional notes
- `docs/UPGRADE.md`: breaking upgrades and migration notes
- Hyprland ecosystem is installed via Hyprnix.
- `nixpkgs-hypr` pinned commit: `dd9b079222d43e1943b6ebd802f04fd959dc8e61`.

## Common Tasks
- Rebuild: `sudo nixos-rebuild switch --flake <path>#<host>`
- Dry run: `sudo nixos-rebuild dry-run --flake <path>#<host>`
- Update inputs: `nix flake update`
- Check flake: `nix flake check`

## Hyprland 0.46 -> 0.54 Upgrade
This repo upgraded Hyprland from 0.46 to 0.54 (breaking changes). Full migration checklist is in `docs/UPGRADE.md`.

Major modifications applied:
- `nixos/tuigreet.nix`: update greetd command to `start-hyprland` (0.53+ requirement).
- `home/system/hyprland/default.nix`:
  - window rules syntax updated for 0.53+
  - fullscreen focus behavior migrated
  - border config moved to the new namespace
  - gestures and layerrule syntax updated

## Notes
- Ensure your GPU/driver supports GLES 3.0 (legacy renderer removed in 0.50).
- Keep `xdg-desktop-portal-hyprland` aligned with the Hyprland version.
