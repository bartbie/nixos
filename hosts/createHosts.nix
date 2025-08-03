{
  nixpkgs,
  darwin,
  systems,
  self,
  ...
}: let
  flake = self;
  inherit (nixpkgs) lib;

  mkSystem = {
    hostname,
    system,
    path ? ./${hostname},
    modules ? [],
    specialArgs ? {},
    class ? "nixos",
  }: let
    inherit (lib) singleton optionals;
    when = klass: x: optionals (class == klass) (lib.flatten x);
    eval =
      if class == "darwin"
      then darwin.lib.darwinSystem
      else nixpkgs.lib.nixosSystem;
  in
    eval {
      specialArgs = lib.recursiveUpdate {inherit flake;} specialArgs;
      modules = lib.concatLists [
        (singleton {
          networking.hostName = hostname;
          nixpkgs.hostPlatform = system;
          nixpkgs.flake.source = nixpkgs.outPath;
        })
        (when "darwin" {
          nixpkgs.source = nixpkgs.outPath;
        })
        (when "iso" "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal-new-kernel.nix")

        modules

        (singleton path)
      ];
    };

  mkHost = hostname: cfg: let
    host-cfg = cfg.hosts.${hostname};
    # modules and specialArgs from different sources combined
    env = let
      get = lib.attrsets.getAttrs ["modules" "specialArgs"];
      sources = [
        cfg.shared
        host-cfg
        (builtins.map cfg.perTag host-cfg.tags)
        (cfg.perClass host-cfg.class)
        (cfg.perArch host-cfg.arch)
      ];
    in
      builtins.foldl' (acc: elem: {
        modules = acc.modules ++ elem.modules;
        specialArgs = lib.recursiveUpdate acc.specialArgs elem.specialArgs;
      }) {
        modules = [];
        specialArgs = {};
      } (builtins.map get (lib.flatten sources));
    class = normalizeClass' cfg host-cfg;
    system-closure = mkSystem ({
        inherit hostname class;
        inherit (host-cfg) system;
      }
      // env);
    namespace =
      if class == "darwin"
      then "darwinConfigurations"
      else "nixosConfigurations";
  in {
    ${namespace}.${hostname} = system-closure;
  };

  mkHosts = cfg:
    lib.foldlAttrs (acc: n: _: lib.recursiveUpdate acc (mkHost n cfg)) {} cfg.hosts;

  coerceSystem = arch: class: let
    postfix =
      if class == "darwin"
      then "darwin"
      else "linux";
  in "${arch}-${postfix}";

  normalizeClass = additionalClasses: class: additionalClasses.${class} or class;
  normalizeClass' = cfg: host-cfg: normalizeClass cfg.additionalClasses host-cfg.class;

  api = let
    inherit (lib) mkOption types;

    mkSharedOptions = name: {
      modules = mkOption {
        type = types.listOf types.deferredModule;
        default = [];
        description = "${name} modules to be included in the system";
      };

      specialArgs = mkOption {
        type = types.lazyAttrsOf types.raw;
        default = {};
        description = "${name} special arguments to be passed to the system";
      };
    };

    mkSharedSubmoduleType = name: types.submodule {options = mkSharedOptions name;};

    mkPerOption = name:
      mkOption {
        type = types.functionTo (mkSharedSubmoduleType name);
        default = _: {
          specialArgs = {};
          modules = [];
        };
      };

    hostType = types.submodule (
      {config, ...}: {
        options =
          {
            arch = mkOption {
              type = types.enum (builtins.map (builtins.replaceStrings ["-darwin" "-linux"] ["" ""]) (import systems));
              default = "x86_64";
            };
            class = mkOption {
              type = types.enum [
                "nixos"
                "darwin"
                "iso"
              ];
              default = "nixos";
            };
            tags = mkOption {
              type = types.listOf types.str;
              default = [];
              example = ["disko" "impermanence"];
            };
            system = mkOption {
              type = types.str;
              default = coerceSystem config.arch config.class;
              example = "x86_64-linux";
              internal = true;
            };
          }
          // (mkSharedOptions "host");
      }
    );
  in ({config, ...}: {
    options = {
      hosts = mkOption {
        type = types.attrsOf hostType;
        default = {};
      };
      shared = mkOption {
        type = mkSharedSubmoduleType "shared";
      };
      perTag = mkPerOption "Per tag";
      perClass = mkPerOption "Per class";
      perArch = mkPerOption "Per arch";

      # taken from easy-hosts directly
      additionalClasses = mkOption {
        default = {};
        type = let
          type = types.attrsOf types.str;
        in
          type
          // {
            check = x: let
              vals = builtins.attrValues x;
              possible-classes = ["nixos" "darwin" "iso"];
            in
              (type.check x) && builtins.all (e: builtins.elem e possible-classes) vals;
          };
        description = "Additional classes and their respective mappings to already existing classes";
        example = lib.literalExpression ''
          {
            wsl = "nixos";
            rpi = "nixos";
            macos = "darwin";
          }
        '';
      };

      ###

      configurations = mkOption {
        internal = true;
        readOnly = true;
        type = let
          confOption = mkOption {
            type = types.nullOr types.anything;
            default = null;
          };
        in
          types.submodule
          {
            options = {
              darwinConfigurations = confOption;
              nixosConfigurations = confOption;
            };
          };
      };
    };

    config = {
      configurations = mkHosts config;
    };
  });
in
  modules: (lib.evalModules {modules = lib.flatten [modules api];}).config.configurations
