{
  inputs,
  config,
  ...
}: let
  this = config.flake.modules;
  switch = default: tag: attrs: attrs.${tag} or default;
  switchM = switch [];
  mods = modules: {inherit modules;};
  modsFor = class: fn: fn this.${class};
in {
  imports = [inputs.easy-hosts.flakeModules.default];
  # extra machinery logic defined in ./machinery/easy-hosts.nix
  # specifically perClass, perHost
  easy-hosts = {
    path = false;
    shared.modules = [
      inputs.wrapper-manager.nixosModules.wrapper-manager
    ];
    additionalClasses = {
      wsl = "nixos";
    };
    perTag = tag:
      mods (switchM tag {
        "disko" = [inputs.disko.nixosModules.disko];
        "impermanence" = [inputs.impermanence.nixosModules.impermanence];
        "lix" = [inputs.lix-module.nixosModules.default];
        "minimal" = [(x: {imports = ["${x.modulesPath}/profiles/minimal.nix"];})];
        "pc" = [this.nixos.pc];
        "server" = [this.nixos.server];
      });
    hosts = {
      lyndon = {
        arch = "x86_64";
        class = "nixos";
        tags = ["disko" "impermanence" "lix" "pc"];
        modules = modsFor "nixos" (m: [
          m.allowUnfree
          m.disko-lyndon
          m.nh
          m.impermanence-btrfs
          m.impermanence-pc
          m.persistPasswordFiles
          m.ssh
          m.hypr
          m.wayland
        ]);
      };
      Roosevelt = {
        arch = "aarch64";
        class = "darwin";
        tags = ["lix" "pc"];
      };
    };
  };
}
