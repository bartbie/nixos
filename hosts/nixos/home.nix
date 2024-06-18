{
  config,
  pkgs,
  ...
} @ inputs: let
  user = "bartbie";
in {
  imports = [
    (import ../../common/home (inputs // {inherit user;}))
  ];

  programs.git = {
    enable = true;
    userName = "bartbie37";
    userEmail = "bartbie37@gmail.com";
  };
}
