{
  nixpkgs,
  self,
  ...
} @ args: let
  inherit (self) inputs;
  inherit (nixpkgs) lib;
  flake = self;
  create = import ./createHosts.nix args;
  switch = default: tag: attrs: attrs.${tag} or default;
in
  create {
    shared = {
      specialArgs = {inherit flake;};
      modules = [
        inputs.wrapper-manager.nixosModules.wrapper-manager
        self.nixosModules.nixon
        {
          nixpkgs.overlays = [
            (self.lib.pkgh.mkUnstableOverlay inputs)
            self.overlays.all
          ];
          nixon.core.enable = lib.mkDefault true; # enable our default config
        }
      ];
    };
    perTag = tag: {
      modules = switch [] tag {
        "disko" = [
          inputs.disko.nixosModules.disko
        ];
        "impermanence" = [
          inputs.impermanence.nixosModules.impermanence
        ];
      };
    };
    additionalClasses = {
      wsl = "nixos";
    };
    hosts = {
      lyndon = {
        arch = "x86_64";
        class = "nixos";
        tags = ["disko" "impermanence"];
      };
      roosevelt = {
        arch = "aarch64";
        class = "darwin";
      };
    };
  }
