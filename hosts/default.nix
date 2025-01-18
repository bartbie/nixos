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
        }
        ./${hostname}
        /*
        Add our module, which has its "default" options enabled by default
        */
        self.nixosModules.user
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
