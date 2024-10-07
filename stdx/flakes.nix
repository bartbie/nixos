{
  nixpkgs,
  home-manager,
  darwin,
  ...
} @ inputs: let
  inherit (nixpkgs) lib;
  inherit (import ./trivial.nix inputs) rpipe;

  home-manager-nixos =
    home-manager.nixosModules.home-manager;

  home-manager-darwin =
    home-manager.darwinModules.home-manager;
in rec {
  shallowMergeList = lib.lists.foldr (x: y: x // y);

  mergeList = lib.lists.foldr lib.attrsets.recursiveUpdate;

  home = opts: {home-manager = opts;};

  addOverlays = overlays: {...}: {nixpkgs.overlays = overlays;};

  # TODO: refactor this (out)
  /*
  helper function for creating a flake for system config.
  creates a set with nixosConfigurations and homeManagerConfiguration.
  variant can be nixos, darwin or null if you only want hm config.
  home-manager can be disabled by setting enable-hm to false.
  Flake inputs are passed in specialArgs.
  */
  mkConfig = {
    variant,
    config-name ? host,
    host,
    system,
    overlays ? null,
    modules,
    enable-hm ? true,
    hm-users,
  }: let
    inherit (lib.attrsets) optionalAttrs mapAttrsToList;
    inherit (lib.lists) forEach foldr optional;
    inherit (builtins) any all isAttrs isList;
    mapToList = mapAttrsToList (_: v: v);
    notNullEmpty = set: name: set ? "${name}" && set."${name}" != null;
  in
    assert any (x: variant == x) ["nixos" "darwin" null];
    assert variant != null -> modules != null;
    assert enable-hm -> isAttrs hm-users;
    assert overlays != null -> isList overlays;
    assert all (user: enable-hm -> (notNullEmpty user "home")) (mapToList hm-users);
    assert all (user: enable-hm -> (notNullEmpty user "modules")) (mapToList hm-users);
    #
      let
        # map users to into a list of sets and shallow merge them
        mapUsers = rpipe [
          (f: mapAttrsToList f hm-users)
          (shallowMergeList {})
        ];

        # we will need to map usets for standalone HM config + system-module one
        toStandalone = user: {
          home,
          modules,
        }: {
          "${user}@${host}" = home-manager.lib.homeManagerConfiguration {
            pkgs = import nixpkgs {inherit system;};
            modules = [home] ++ modules;
          };
        };
        toSystemModuleUsers = user: {
          home,
          modules,
        }: {"${user}" = import home;};

        mkArgs = hm-module: {
          inherit system;
          specialArgs = {inherit inputs;};
          modules =
            modules
            ++ (optional (overlays != null) (addOverlays overlays))
            ++ (optional enable-hm hm-module)
            ++ (optional enable-hm)
            (home {
              useGlobalPkgs = true;
              useUserPackages = true;
              users = mapUsers toSystemModuleUsers;
            });
        };
      in
        optionalAttrs (variant == "nixos")
        {
          nixosConfigurations."${config-name}" = lib.nixosSystem (mkArgs home-manager-nixos);
        }
        // optionalAttrs (variant == "darwin") {
          darwinConfigurations."${config-name}" = darwin.lib.darwinSystem (mkArgs home-manager-darwin);
        }
        // optionalAttrs enable-hm {
          homeConfigurations = mapUsers toStandalone;
        };

  mkHomeManagerConfig = arg:
    mkConfig (arg
      // {
        enable-hm = true;
        variant = null;
      });
  mkWithoutHMConfig = arg: mkConfig (arg // {enable-hm = false;});
}
