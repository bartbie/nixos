{
  config,
  pkgs,
  ...
}: {
  imports = [
    ../../common/home/main.nix
    ../../common/home/programs/git-personal.nix
  ];
  mine.home.user = "bartbie";
}
