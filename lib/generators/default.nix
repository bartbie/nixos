{
  lib,
  final,
  ...
}:
{
  mkModprobeConfig =
    let
      # TODO: this only adds `options`, either rename or expand
      at = lib.attrsets;
      concat = lib.flip lib.pipe [
        (lib.concatStringsSep " ")
        lib.trim
      ];
    in
    lib.flip lib.pipe [
      (at.mapAttrs (_: concat))
      (at.filterAttrs (_: v: v != ""))
      (at.mapAttrsToList (n: v: "options ${n} ${v}"))
      lib.concatLines
    ];
  mapCmdsForSudo =
    options:
    builtins.map (cmd: {
      inherit options;
      command = "/run/current-system/sw/bin/${cmd}";
    });

  hypr = import ./tohyprconf.nix { inherit lib final; };
}
