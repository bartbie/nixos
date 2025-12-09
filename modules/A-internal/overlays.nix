{
  lib,
  config,
  ...
}: let
  # taken from
  # https://github.com/NixOS/nixpkgs/blob/d9bc5c7dceb30d8d6fafa10aeb6aa8a48c218454/nixos/modules/misc/nixpkgs.nix#L47-L52
  overlayType = lib.mkOptionType {
    name = "nixpkgs-overlay";
    description = "nixpkgs overlay";
    check = lib.isFunction;
    merge = lib.mergeOneOption;
  };
  # taken from
  # https://github.com/NixOS/nixpkgs/blob/d9bc5c7dceb30d8d6fafa10aeb6aa8a48c218454/nixos/modules/misc/nixpkgs.nix#L174-L195
  overlayOption = lib.mkOption {
    default = [];
    example = lib.literalExpression ''
      [
        (self: super: {
          openssh = super.openssh.override {
            hpnSupport = true;
            kerberos = self.libkrb5;
          };
        })
      ]
    '';
    type = lib.types.listOf overlayType;
    description = ''
      List of overlays to apply to Nixpkgs.
      This option allows modifying the Nixpkgs package set accessed through the `pkgs` module argument.

      For details, see the [Overlays chapter in the Nixpkgs manual](https://nixos.org/manual/nixpkgs/stable/#chap-overlays).

      If the {option}`nixpkgs.pkgs` option is set, overlays specified using `nixpkgs.overlays` will be applied after the overlays that were already included in `nixpkgs.pkgs`.
    '';
  };
in {
  options.overlays = lib.genAttrs ["common" "stable" "unstable"] (_: overlayOption);
  config.overlays = lib.genAttrs ["stable" "unstable"] (_: config.overlays.common);
}
