{
  lib,
  inputs,
  config,
  ...
}:
let
  flakeConfig = config;
in
lib.mergeAttrsList [
  # lib
  (
    let
      inherit (config.flake) nixonLib;
      inherit (nixonLib) theme;
    in
    {
      nixonArgs = { inherit nixonLib theme; };
    }
  )

  # nixpkgs
  (
    let
      mkNixpkgs =
        system: config:
        import inputs.nixpkgs {
          inherit system;
          overlays = flakeConfig.overlays.stable;
          inherit config;
        };
      mkNixpkgsUnstable =
        system: config:
        import inputs.nixpkgs-unstable {
          inherit system;
          overlays = flakeConfig.overlays.unstable;
          inherit config;
        };
    in
    {
      perSystem =
        { system, ... }:
        {
          nixonArgs = {
            pkgs = mkNixpkgs system { };
            pkgs-unstable = mkNixpkgsUnstable system { };
          };
        };

      hosts.shared =
        { pkgs, config, ... }:
        {
          nixpkgs = {
            overlays = flakeConfig.overlays.stable;
          };
          nixonArgs =
            let
              # SAFETY:
              # set system from config.nixpkgs, otherwise infrec from specialArgs
              # system = config.nixpkgs.stdenv.hostPlatform;
              inherit (pkgs.stdenv.hostPlatform) system;
            in
            {
              inherit system;
              pkgs-unstable = mkNixpkgsUnstable system config.nixpkgs.config;
            };
        };
    }
  )
]
