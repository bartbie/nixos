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
            (self.lib.mkUnstableOverlay inputs)
            self.overlays.all # add our packages
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
