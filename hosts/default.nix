{
  nixpkgs,
  self,
  ...
}: let
  inherit (self) inputs;
  inherit (nixpkgs) lib;
  mkHost = builder: hostname: system:
    builder {
      inherit system;
      modules = [
        {
          networking.hostName = hostname;
          nixpkgs.hostPlatform = system;
          nixpkgs.overlays = [
            (final: _: {
              unstable = import inputs.nixpkgs-unstable {
                inherit (final) system config;
              };
            })
            inputs.bartbie-nvim.overlays.default
          ];
          nixon.core.enable = lib.mkDefault true; # enable our default config
        }
        ./${hostname}
        # Add our module
        self.nixosModules.nixon
      ];
      specialArgs = {
        inherit inputs;
        flake = self;
      };
    };
  mkHostArgs = mkHost lib.id;
in {
  lyndon = mkHost lib.nixosSystem "lyndon" "x86_64-linux";
}
