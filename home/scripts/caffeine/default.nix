# - ## Caffeine
#-
#- Caffeine is a simple script that toggles hypridle (disable suspend & screenlock).
#-
#- - `caffeine-status` - Check if hypridle is running. (0/1)
#- - `caffeine-status-icon` - Check if hypridle is running. (icon)
#- - `caffeine` - Toggle hypridle.

{ pkgs, ... }:
let
  caffeine-status = pkgs.writeShellScriptBin "caffeine-status" ''
    [[ $(pidof "hypridle") ]] && echo "0" || echo "1"
  '';

  caffeine-status-icon = pkgs.writeShellScriptBin "caffeine-status-icon" ''
    [[ $(pidof "hypridle") ]] && echo "󰾪" || echo "󰅶"
  '';

  caffeine = pkgs.writeShellScriptBin "caffeine" ''
        icon_dir="''${XDG_RUNTIME_DIR:-/tmp}/caffeine-icons"
        mkdir -p "$icon_dir"

        if [[ $(pidof "hypridle") ]]; then
          systemctl --user stop hypridle.service
          glyph="󰅶"
          icon="$icon_dir/activated.svg"
          title="Caffeine Activated"
          description="Caffeine is now active!\nYour screen will not turn off automatically."
        else
          systemctl --user start hypridle.service
          glyph="󰾪"
          icon="$icon_dir/deactivated.svg"
          title="Caffeine Deactivated"
          description="Caffeine is now deactivated!\nYour screen will turn off automatically."
        fi

        cat > "$icon" <<EOF
    <svg xmlns="http://www.w3.org/2000/svg" width="128" height="128" viewBox="0 0 128 128">
      <rect width="128" height="128" rx="24" fill="#11111b"/>
      <text x="58" y="90" text-anchor="middle" dominant-baseline="central"
            font-family="Symbols Nerd Font Mono, Symbols Nerd Font, monospace"
            font-size="72" fill="#cba6f7">$glyph</text>
    </svg>
    EOF

        ${pkgs.libnotify}/bin/notify-send \
          --icon="$icon" \
          --app-name="caffeine" \
          --hint="string:x-canonical-private-synchronous:caffeine" \
          --hint="string:desktop-entry:caffeine" \
          --hint="int:transient:1" \
          "$title" \
          "$description"
  '';

in { home.packages = [ caffeine-status caffeine caffeine-status-icon ]; }
