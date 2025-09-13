{
  lib,
  config,
  ...
}: let
  #                  class                 name                   module
  regularHostsType = lib.types.lazyAttrsOf (lib.types.lazyAttrsOf (lib.types.deferredModule));

  hostsType = lib.types.mkOptionType {
    name = "hostsWithShared";
    description = "Hosts attribute set with special 'shared' key";
    descriptionClass = "composite";
    check = builtins.isAttrs;
    merge = loc: defs: let
      # split into shared and non-shared parts
      regulars =
        defs
        |> builtins.map (def: def // {value = builtins.removeAttrs def.value ["shared"];})
        |> regularHostsType.merge loc;

      shared = let
        filtered =
          defs
          |> builtins.filter (def: def.value ? shared);
        merged =
          filtered
          |> builtins.map (def: def // {value = def.value.shared;})
          |> lib.types.deferredModule.merge (loc ++ ["shared"]);
      in
        lib.optionalAttrs (filtered != []) {shared = merged;};
    in
      regulars // shared;
  };
in {
  options.hosts = lib.mkOption {
    type = hostsType;
    description = "Hosts attribute set with special 'shared' key";
    example = lib.options.literalExpression ''
      hosts.nixos.lyndon = {pkgs,...}: {
        environment.systemPackages = [pkgs.hello];
      };
      hosts.shared = {pkgs,...}: { environment.systemPackages = [pkgs.hello]; }
    '';
  };

  config.flake.modules.generic.hostShared = config.hosts.shared;
}
