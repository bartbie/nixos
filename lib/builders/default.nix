{
  lib,
  final,
  ...
} @ args: pkgs: let
  self = args.self pkgs;
  safeInherit = basePackage: list: lib.filterAttrs (n: v: basePackage ? ${n}) list;
  _symlinkDrv = drv: let
    outputs = drv.outputs or ["out"];
    attrs =
      (safeInherit drv ["meta" "version" "meta" "name" "pname"])
      // {
        inherit outputs;
        passthru = (drv.passthru or {}) // {unwrapped = drv;};
      };
  in
    pkgs.runCommand "${drv.name}-symlinked" attrs
    #sh
    ''
      set -euo pipefail

      ${
        outputs
        |> lib.concatMapStringsSep "\n" (output:
          #sh
          ''
            # Symlink everything from original output
            if [ -d "${drv.${output}}" ]; then
              echo "Symlinking ${output}"
              set -x
              cp -rs --no-preserve=mode "${drv.${output}}" "''${${output}}" || {
                set +x
                echo "Failed to symlink ${output}" >&2
                exit 1
              }
              set +x
            else
              echo "Warning: ${output} output not found" >&2
            fi
          '')
      }
    '';
in {
  symlinkDrv = drv:
    assert lib.isDerivation drv;
      if drv ? override
      then
        lib.makeOverridable (
          new:
            _symlinkDrv (drv.override new)
        ) {}
      else _symlinkDrv drv;
}
