{
  inputs,
  config,
  lib,
  options,
  ...
}: let
  switch = default: tag: attrs: attrs.${tag} or default;
  switchM = switch [];
in {
  imports = [inputs.easy-hosts.flakeModules.modules];
  easy-hosts = {
    path = false;
    shared = a: {
      modules = [
        inputs.wrapper-manager.nixosModules.wrapper-manager
        # INFO: load our host-specific config in form of flake-parts.modules module
        (config.flake.modules.${a.class}.hosts.${a.name} or {})

        # INFO: pass metadata to our configs
        {
          options.meta = let
            inherit (lib) types;
            mkMarker = default: type:
              lib.mkOption {
                inherit type default;
                internal = true;
                readOnly = true;
              };
          in {
            tags = mkMarker a.tags (types.listOf types.str);
            class = mkMarker a.class (types.str);
          };
        }
      ];
    };
    perClass = class: {
      modules = [
        # INFO: load base of our config
        (config.flake.modules.${class}.base or {})
      ];
    };
    perTag = tag: {
      modules = switchM tag {
        "disko" = [inputs.disko.nixosModules.disko];
        "impermanence" = [inputs.impermanence.nixosModules.impermanence];
        "lix" = [inputs.lix-module.nixosModules.default];
        "minimal" = [(x: {imports = ["${x.modulesPath}/profiles/minimal.nix"];})];
        "pc" = [config.flake.modules.nixos.pc];
        "server" = [config.flake.modules.nixos.server];
      };
    };
    additionalClasses = {
      wsl = "nixos";
    };
    hosts = {
      lyndon = {
        arch = "x86_64";
        class = "nixos";
        tags = ["disko" "impermanence" "lix" "pc"];
        add = m: [
          m.allowUnfree
          m.disko-lyndon
          m.nh
          m.impermanence-btrfs
          m.impermanence-pc
          m.persistPasswordFiles
          m.ssh
          m.users-bartbie
          m.hypr
          m.wayland
        ];
      };
      Roosevelt = {
        arch = "aarch64";
        class = "darwin";
        tags = ["lix" "pc"];
      };
    };
  };
}
