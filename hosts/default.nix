{
  nixpkgs,
  self,
  ...
} @ inputs: let
  inherit (nixpkgs) lib;
  mkHost = builder: hostname: system:
  # modules:
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
        # ]
        # ++ modules
        # ++ [
        self.user
        ./${hostname}
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
