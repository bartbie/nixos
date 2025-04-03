{
  lib,
  final,
  ...
} @ args: pkgs: let
  self = args.self pkgs;
in {
  symlinkDrv = drv: let
    outputs = drv.outputs or ["out"];
    symlink-all = lib.pipe outputs [
      (builtins.map (output:
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
        ''))
      lib.concatLines
    ];
  in
    pkgs.runCommand "${drv.name}-overridden" ({
        inherit outputs;
        inherit (drv) meta;
        passthru = (drv.passthru or {}) // {unwrapped = drv;};
      }
      // (lib.optionalAttrs (drv ? version) {inherit (drv) version;}))
    #sh
    ''
      set -euo pipefail

      ${symlink-all}
    '';

  symlinkDrvOverridable = drv:
    lib.makeOverridable (new:
      self.symlinkDrv (drv.override new))
    {};
}
