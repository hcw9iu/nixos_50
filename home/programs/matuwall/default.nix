{ pkgs, lib, inputs, config, ... }:
let
  gtkLayerShell =
    if builtins.hasAttr "gtk4-layer-shell" pkgs then
      pkgs."gtk4-layer-shell"
    else
      pkgs.gtk-layer-shell;

  matuwall = pkgs.python3Packages.buildPythonApplication {
    pname = "matuwall";
    version = "0-unstable";
    src = inputs.matuwall;
    pyproject = true;

    postPatch = ''
      substituteInPlace pyproject.toml \
        --replace 'license = "GPL-3.0-or-later"' 'license = { text = "GPL-3.0-or-later" }'
    '';

    nativeBuildInputs = [
      pkgs.wrapGAppsHook4
      pkgs.gobject-introspection
      pkgs.python3Packages.setuptools
      pkgs.python3Packages.wheel
    ];

    buildInputs = [
      pkgs.gtk4
      pkgs.libadwaita
      gtkLayerShell
      pkgs.glib
    ];

    propagatedBuildInputs = with pkgs.python3Packages; [
      pygobject3
    ];
  };

  awwwPkg = if builtins.hasAttr "awww" pkgs then pkgs.awww else null;
in {
  home.packages = [ matuwall pkgs.swww ]
    ++ lib.optional (awwwPkg != null) awwwPkg
    ++ [
      (pkgs.writeShellScriptBin "awww" ''
        if [ "''${1:-}" = "img" ]; then
          shift
          exec ${pkgs.swww}/bin/swww img "$@"
        fi
        echo "awww wrapper: unsupported args: $*" >&2
        exit 2
      '')
      (pkgs.writeShellScriptBin "awww-daemon" ''
        if ! pgrep -x swww-daemon >/dev/null 2>&1; then
          ${pkgs.swww}/bin/swww-daemon "$@" &
        fi
        # Keep this process alive so matuwall can detect "awww-daemon"
        while pgrep -x swww-daemon >/dev/null 2>&1; do
          sleep 5
        done
      '')
    ];


  home.file.".local/bin/matuwall-toggle" = {
    executable = true;
    text = ''
      #!/usr/bin/env sh
      exec /etc/profiles/per-user/${config.var.username}/bin/matuwall --toggle
    '';
  };

  systemd.user.services = { };


  xdg.configFile."matuwall/config.json".text = ''
    {
      "main": {
        "wallpaper_dir": "${config.home.homeDirectory}/Pictures/WallPaper",
        "gtk_theme": "",
        "icon_theme": "",
        "favorited_wallpaper_dir": "",
        "show_symlink_origin": false,
        "keep_ui_alive": true
      },
      "panel": {
        "panel_mode": false,
        "panel_edge": "left",
        "panel_thumbs_col": 4
      },
      "wall": {
        "wall_mode_only": true,
        "wall_awww_flags": [
          "--transition-type",
          "grow",
          "--transition-duration",
          "0.4"
        ]
      }
    }
  '';
}
