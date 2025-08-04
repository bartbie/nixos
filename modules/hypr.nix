{
  flake.modules.nixos.hypr = {pkgs, ...}: {
    programs.hyprland = {
      enable = true;
      package = pkgs.nixon.Hyprland;
      withUWSM = true;
    };
  };
}
