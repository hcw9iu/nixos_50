{ config, ... }:
let
  username = config.var.username;
in {
  xdg.configFile = {
    "wlogout/layout".source = ./layout;
    "wlogout/themes/catppuccin".source = ./themes/catppuccin;
    "wlogout/icons".source = ./icons;
    "wlogout/style.css".text = ''
      * {
      	background-image: none;
      	box-shadow: none;
      }

      window {
      	font-size: 8pt;
      	background-color: rgba(32, 31, 31, 0.3);
      }

      button {
          border-radius: 25px;
          border-color: #18191a;
      	text-decoration-color: #FFFFFF;
          color: #FFFFFF;
      	background-color: #11111b;
      	border-style: solid;
      	border-width: 0px;
      	background-repeat: no-repeat;
      	background-position: center;
      	background-size: 25%;
      	margin: 5px;
      }

      box#buttons {
        margin: 0;
      }

      box#buttons > button {
        min-width: 90px;
        min-height: 90px;
      }


      button:focus, button:active, button:hover {
      	background-color: rgba(5, 5, 5, 0.3);
      	outline-style: none;
      	background-size: 35%;
      	transition: all 0.2s cubic-bezier(.55,0.0,.28,1.682);
      }

      button label {
        color: transparent;
        font-size: 0px;
      }

      #lock {
      background-image: image(url("/home/${username}/.config/wlogout/icons/lock.png"));
      }

      #logout {
      background-image: image(url("/home/${username}/.config/wlogout/icons/logout.png"));
      }

      #shutdown {
      background-image: image(url("/home/${username}/.config/wlogout/icons/shutdown.png"));
      }

      #reboot {
      background-image: image(url("/home/${username}/.config/wlogout/icons/reboot.png"));
      }

      #suspend {
      background-image: image(url("/home/${username}/.config/wlogout/icons/suspend.png"));
      }

      #caffeine {
      background-image: image(url("/home/${username}/.config/wlogout/icons/caffeine.png"));
      }
    '';
  };

  home.file.".local/bin/wlogout-menu" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      exec wlogout \
        --layout "$HOME/.config/wlogout/layout" \
        --css "$HOME/.config/wlogout/style.css" \
        --buttons-per-row 6
    '';
  };
}
