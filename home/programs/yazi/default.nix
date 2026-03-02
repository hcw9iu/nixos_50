# Yazi is a TUI file explorer

{
  programs.yazi = {
    enable = true;
    enableZshIntegration = true;

    settings = {
      log = { enabled = false; };
      manager = {
        show_hidden = false;
        sort_by = "modified";
        sort_dir_first = true;
        sort_reverse = true;
      };
    };
  };
}

/*
{ pkgs, ... }:
{
  programs.yazi = {
    enable = true;
    enableZshIntegration = true;

    settings = {
      log = { enabled = false; };

      manager = {
        show_hidden = false;
        sort_by = "modified";
        sort_dir_first = true;
        sort_reverse = true;
      };

      opener = {
        edit = [
          { run = ''nvim "$@"''; block = true; desc = "nvim"; }
        ];
        open = [
          { run = ''xdg-open "$1"''; desc = "Open"; }
        ];
      };

      open = {
        rules = [
          { mime = "text/*"; use = "edit"; }
          { name = "*.nix";  use = "edit"; }
          { name = "*.lua";  use = "edit"; }
          { name = "*.md";   use = "edit"; }
          { name = "*.sh";   use = "edit"; }
          { name = "*.py";   use = "edit"; }
          { name = "*.js";   use = "edit"; }
          { name = "*.ts";   use = "edit"; }
          { name = "*.json"; use = "edit"; }
          { name = "*.toml"; use = "edit"; }
          { name = "*.yaml"; use = "edit"; }
          { name = "*.yml";  use = "edit"; }
          { use = "open"; }
        ];
      };
    };
  };

  home.packages = with pkgs; [
    xdg-utils
    file
    #neovim
  ];

  programs.zsh.initExtra = ''
    export EDITOR=nvim
    export VISUAL=nvim
  '';
}
*/




