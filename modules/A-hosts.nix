{
  lib,
  inputs,
  config,
  ...
}:
let
  this = config.flake.modules;
  switch =
    default: tag: attrs:
    attrs.${tag} or default;
  switchM = switch [ ];
  mods = modules: { inherit modules; };

  checkedTags =
    let
      names = path: this |> lib.attrByPath [ path ] { } |> builtins.attrNames;
    in
    class: tags:
    assert lib.asserts.assertEachOneOf "tags" tags ((names class) ++ (names "generic"));
    tags;

  tags =
    class:
    {
      checked ? [ ],
      unchecked ? [ ],
    }:
    unchecked ++ (checkedTags class checked);
in
{
  imports = [ inputs.easy-hosts.flakeModules.default ];
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
    perTag =
      tag:
      mods (
        switchM tag {
          "disko" = [ inputs.disko.nixosModules.disko ];
          "impermanence" = [ inputs.impermanence.nixosModules.impermanence ];
          "minimal" = [ (x: { imports = [ "${x.modulesPath}/profiles/minimal.nix" ]; }) ];
        }
      );
    hosts = {
      lyndon = {
        arch = "x86_64";
        class = "nixos";
        tags = tags "nixos" {
          unchecked = [
            "disko"
            "impermanence"
            "pc"
          ];
          checked = [
            "allowUnfree"
            "nh"
            "impermanence-btrfs"
            "impermanence-pc"
            "persistPasswordFiles"
            "ssh-client"
            "ssh-server"
            "tailscale"
            "hypr"
            "wayland"
            "cuda"
          ];
        };
      };
      Roosevelt = {
        arch = "aarch64";
        class = "darwin";
        tags = [ "pc" ];
      };
    };
  };
}
