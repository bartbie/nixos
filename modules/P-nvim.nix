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
        name = "nixon-dev-nvim-shell";
        packages = [ (nvimForSystem system) ];
        inputsFrom = [ self'.devShells.devBasic ];
      };
    };
}
