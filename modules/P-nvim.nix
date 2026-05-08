{
  lib,
  inputs,
  ...
}:
let
  nvimForSystem = system: inputs.bartbie-nvim.packages.${system}.nvim;
in
{
  hosts.shared =
    { system, ... }:
    {
      environment.systemPackages = [ (nvimForSystem system) ];
      environment.variables.EDITOR = "nvim";
    };
  perSystem =
    {
      pkgs,
      system,
      self',
      ...
    }:
    {
      devShells.devWithNvim = pkgs.mkShell {
        name = "nixon-shell-nvim";
        packages = [ (nvimForSystem system) ];
        inputsFrom = [ self'.devShells.devBase ];
      };
    };
}
