# Eza is a ls replacement
{
  programs.eza = {
    enable = true;
    icons = "auto";
    #icons = true;

    extraOptions = [
      "--group-directories-first"
      "--no-quotes"
      "--git-ignore"
      "--icons=always"
    ];
  };
}
