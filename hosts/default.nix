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
        ({config, ...}: {
          networking.hostName = hostname;
          nixpkgs.hostPlatform = system;
          nixpkgs.overlays = [
            (self.lib.pkgh.mkUnstableOverlay inputs)
            self.overlays.all
          ];
          nixon.core.enable = lib.mkDefault true; # enable our default config
          disko.enableConfig = lib.mkDefault (config.disko.devices != {});
        })
        ./${hostname}
        # Add our module
        self.nixosModules.nixon
        # Add modules that will are or will get disabled by default
        inputs.disko.nixosModules.disko
        inputs.impermanence.nixosModules.impermanence
        inputs.wrapper-manager.nixosModules.wrapper-manager
      ];
      specialArgs = {
        flake = self;
      };
    };
  mkHostArgs = mkHost lib.id;
in {
  lyndon = mkHost lib.nixosSystem "lyndon" "x86_64-linux";
}
