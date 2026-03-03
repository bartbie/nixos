{
  lib,
  config,
  withSystem,
  ...
}:
let
  inherit (config) flake;
in
{
  flake.modules.nixos.hypr =
    {
      pkgs,
      self',
      inputs',
      ...
    }:
    let
      package = self'.packages.hypr;
    in
    {
      programs.hyprland = {
        inherit package;
        enable = true;
        withUWSM = true;
      };
      xdg.portal.config.hyprland = {
        default = [
          "hyprland"
          "gtk"
        ];
      };
      environment.systemPackages = package.passthru.runtimeInputs ++ [
        inputs'.hyprland-guiutils.packages.default
      ];
    };
  wrapped.hypr = {
    systems = config.meta.systemsNoDarwin;

    module =
      {
        pkgs,
        pkgs-unstable,
        nixonLib,
        theme,
        overrideArgs,
        self',
        inputs',
        wrapperManagerLib,
        nixonArgs,
        ...
      }:
      let
        module-filter-list = [ ];
        configDrvs =
          let
            evalResult =
              flake.modules.hypr
              |> (x: builtins.removeAttrs x module-filter-list)
              |> builtins.attrValues
              |> (
                mods:
                lib.evalModules {
                  class = "hypr";
                  modules = lib.flatten [
                    flake.modules.generic.assertions
                    mods
                  ];
                  specialArgs = withSystem pkgs.hostPlatform.system (
                    {
                      self',
                      inputs',
                      system,
                      ...
                    }:
                    {
                      inherit
                        pkgs
                        pkgs-unstable
                        self'
                        inputs'
                        system
                        nixonArgs
                        ;
                    }
                    // nixonArgs
                  );
                }
              )
              |> (x: x.config)
              |> (
                x:
                assert nixonLib.assertions.checkAssertions x.assertions;
                x
              );
          in
          evalResult
          |> (x: lib.getAttrs x.out x)
          |> builtins.mapAttrs (
            name: configAttrs:
            let
              configText = nixonLib.generators.hypr.configToHyprconf { config = configAttrs; };
              runtimeInputs = evalResult.runtimeInputs.${name} or [ ];
            in
            (pkgs.writeText "Hypr-${name}-nixon.conf" configText).overrideAttrs (prev: {
              passthru = lib.recursiveUpdate prev.passthru {
                inherit configText configAttrs runtimeInputs;
              };
            })
          );

        package =
          { wrapRuntimeDeps = false; } |> pkgs-unstable.hyprland.override |> (x: x.override overrideArgs);

        test =
          let
            grep-tmp = lookup-pat: ignore-pat: capture-pat: ''
              grep "${lookup-pat}" $TMP/output.log | sed -n 's/${ignore-pat}\(${capture-pat}\)/\1/p' || true
            '';
          in
          # sh
          ''
            run_and_filter() {
                if ! "$@" > $TMP/output.log 2>&1; then
                    ${grep-tmp "ERR" ".*]: *" ".*"}
                    ${grep-tmp "WARN" ".*]: *" ".*"}
                    ${grep-tmp "Config error" ".*" "line [0-9]*:.*"}
                    return 1
                fi
                return 0
            }
            XDG_RUNTIME_DIR="" run_and_filter $out/bin/Hyprland --verify-config
          '';
      in
      {
        single = {
          inherit package;
          wrapper = {
            prependArgs = [
              "--config"
              configDrvs.land
            ];
            pathAdd = wrapperManagerLib.getBin [
              pkgs.binutils
              # pkgs-unstable.hyprland-qtutils
              inputs'.hyprland-guiutils.packages.default
              pkgs.pciutils
              pkgs.pkgconf
            ];
          };
        };
        build = {
          extraPassthru = {
            inherit configDrvs;
            tests.verify-config = test;
            runtimeInputs = configDrvs |> lib.mapAttrsToList (_: v: v.passthru.runtimeInputs) |> lib.flatten;
          };

          extraSetup =
            #sh
            ''
              base=${package.out}
              # Symlink everything from original $out except base pkg
              echo "Symlinking $out"
              set -x
              find "$base" -type d -printf '%P\n' | while read -r dir; do
                mkdir -p "$out/$dir"
              done
              find $base -type f ! -name 'Hyprland' -printf '%P\n' | while read -r file; do
                ln -s "$base/$file" "$out/$file" || {
                set +x
                echo "Failed to symlink $file" >&2
                exit 1
              }
              done
              # symlink config to share to make debugging easier
              ${
                configDrvs
                |> builtins.attrValues
                |> builtins.map (drv: ''
                  ln -s "${drv}" "$out/share/${drv.name}" || {
                    set +x
                    echo "Failed to symlink ${drv}" >&2
                    exit 1
                  }
                '')
                |> lib.join "\n"
              }
              set +x
            '';
        };
        # HACK:
        # create new drv on top of wrapper with --verify-config as its installCheck phase
        finalMapDrv =
          old:
          let
            pickAttrs =
              l: at:
              assert builtins.isList l;
              l |> (x: lib.genAttrs x (_: null)) |> (x: builtins.intersectAttrs x at);
            mkDrv =
              l:
              assert builtins.isList l;
              l |> lib.flatten |> lib.mergeAttrsList |> pkgs.stdenv.mkDerivation;

            outputs = old.outputs or [ "out" ];
          in
          mkDrv [
            (pickAttrs [ "name" "meta" "pname" "version" ] old)
            {
              inherit outputs;
              passthru = (old.passthru or { }) // {
                unwrapped = old;
              };

              buildInputs = [ self'.packages.linktree ];
              OLD = old;
              phases = [
                "installPhase"
                "installCheckPhase"
              ];

              installPhase = ''
                ${pkgs.lib.concatMapStringsSep "\n" (output: ''
                  # Symlink everything from original output
                  if [ -d "${old.${output}}" ]; then
                    echo "Symlinking ${output}"
                    # set -x
                    linktree ${old.${output}} ''${${output}} || {
                      # set +x
                      echo "Failed to symlink ${output}" >&2
                      exit 1
                    }
                    # set +x
                  else
                    echo "Warning: ${output} output not found" >&2
                  fi
                '') outputs}
              '';

              doInstallCheck = true;
              installCheckPhase = ''
                ${test}
              '';
            }
          ];
      };
  };
}
