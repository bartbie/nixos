{
  lib,
  inputs,
  config,
  ...
}:
let
  inherit (inputs) deploy-rs;

  helpers =
    # HACK: i was lazy and just ripped easy-hosts bunch of internals and glued it back together
    let
      redefineClass =
        additionalClasses: class: ({ linux = "nixos"; } // additionalClasses).${class} or class;

      classToOS = class: if (class == "darwin") then "darwin" else "linux";

      constructSystem =
        additionalClasses: arch: class:
        let
          class' = redefineClass additionalClasses class;
          os = classToOS class';
        in
        "${arch}-${os}";

      _getClass = additionalClasses: class: (redefineClass additionalClasses class) |> classToOS;

      _getConfigSet =
        additionalClasses: cfg: class:
        if (_getClass additionalClasses class) == "darwin" then
          cfg.darwinConfigurations
        else
          cfg.nixosConfigurations;
    in
    {
      getSystem = constructSystem config.easy-hosts.additionalClasses;
      getConfigSet = _getConfigSet config.easy-hosts.additionalClasses config.flake;
    };
in
{
  flake.checks =
    deploy-rs.lib |> builtins.mapAttrs (system: deployLib: deployLib.deployChecks config.flake.deploy);

  flake.deploy.nodes =
    config.easy-hosts.hosts
    |> lib.filterAttrs (_: v: v.deployable or false)
    |> builtins.mapAttrs (
      hostname: v:
      let
        system = helpers.getSystem v.arch v.class;
        configSet = helpers.getConfigSet v.class;
        nixpkgs = inputs.nixpkgs;

        # dont like it but nixpkgs should only be evaluated when deploying?
        # so should be okay
        pkgs = import nixpkgs { inherit system; };
        # nixpkgs with deploy-rs overlay but force the nixpkgs package
        deployPkgs = import nixpkgs {
          inherit system;
          overlays = [
            deploy-rs.overlays.default
            (self: super: {
              deploy-rs = {
                inherit (pkgs) deploy-rs;
                lib = super.deploy-rs.lib;
              };
            })
          ];
        };
      in
      {
        inherit hostname;
        profiles.system = {
          user = "root";
          path = deployPkgs.deploy-rs.lib.activate.nixos configSet.${hostname};
        };
      }
    );

}
