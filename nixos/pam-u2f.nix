{ config, pkgs, ... }:
{
  # Enable pam_u2f for FIDO2/U2F unlock
  security.pam.u2f.enable = true;

  # Choose one:
  # "sufficient" = key-only unlock (password still works)
  # "required"   = key + password (2FA)
  security.pam.u2f.control = "sufficient";

  # Ensure hyprlock has a PAM service
  security.pam.services.hyprlock = {};
}
