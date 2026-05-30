let
  cache = "https://bartbie.cachix.org?priority=15";
in
{
  flake.modules.nixos = {
    base = {
      nix.settings = {
        substituters = [ cache ];
        trusted-substituters = [ cache ];
        trusted-public-keys = [
          "bartbie.cachix.org-1:sX0rzre7TKHN949pzOO5mWubI/6uXKIoMCzRZPnHbDI="
        ];
      };
    };
    pc =
      { pkgs-unstable, ... }:
      {
        environment.systemPackages = [ pkgs-unstable.cachix ];
      };
  };
}
