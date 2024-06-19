{
  config,
  pkgs,
  ...
} @ inputs: let
  user = "bartbie";
in {
  imports = [
    (import ../../common/home (inputs // {inherit user;}))
    ../../common/home/programs/git-personal.nix
  ];
}
