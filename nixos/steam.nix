{ pkgs, ... }:
{
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true; # 開啟防火牆（如果需要遠端遊玩）
    dedicatedServer.openFirewall = true; # 開啟防火牆（如果需要專用伺服器）
  };
}