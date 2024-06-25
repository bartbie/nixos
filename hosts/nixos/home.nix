{
  config,
  pkgs,
  ...
}: {
  imports = [
    ../../common/home/main.nix
    ../../common/home/programs/git-personal.nix
    # ../../common/home/programs/hyprland.nix
  ];
  mine.home.user = "bartbie";
}
