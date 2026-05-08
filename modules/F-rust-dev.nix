{
  lib,
  inputs,
  nixonLib,
  ...
}:
{
  perSystem =
    {
      self',
      pkgs,
      pkgs-unstable,
      ...
    }:
    let
      moldStdenv = pkgs.stdenvAdapters.useMoldLinker pkgs.stdenv;
      # avoid overlay https://github.com/oxalica/rust-overlay/issues/209#issuecomment-2691408990
      rust-bin = (lib.fix (final: pkgs // (import inputs.rust-overlay) final pkgs)).rust-bin;
      toolchain = rust-bin.stable.latest.default.override (p: {
        extensions = p.extensions ++ [
          "rust-src"
          "rust-analyzer"
        ];
      });
      naersk' = pkgs.callPackage inputs.naersk {
        cargo = toolchain;
        rustc = toolchain;
      };
    in
    {
      devShells.rust = (pkgs.mkShell.override { stdenv = moldStdenv; }) {
        name = "nixon-shell-rust";
        inputsFrom = [ self'.devShells.devBase ];
        # Build-time dependencies. build = host = your-machine, target = aarch64
        # Typically contains,
        # - Configure-related: cmake, pkg-config
        # - Compiler-related: gcc, rustc, binutils
        # - Code generators run at build time: yacc, bision
        nativeBuildInputs = [
          pkgs.pkg-config
          toolchain
        ];
        # Build-time tools which are target agnostic. build = host = target = your-machine.
        # Emulaters should essentially also go `nativeBuildInputs`. But with some packaging issue,
        # currently it would cause some rebuild.
        # We put them here just for a workaround.
        # See: https://github.com/NixOS/nixpkgs/pull/146583
        depsBuildBuild = [ ];
        # Run-time dependencies. build = your-machine, host = target = aarch64
        # Usually are libraries to be linked.
        buildInputs = [ ];
        env.RUST_SRC_PATH = "${toolchain}/lib/rustlib/src/rust/library";
        # # Tell cargo about the linker and an optional emulater. So they can be used in `cargo build`
        # # and `cargo run`.
        # # Environment variables are in format `CARGO_TARGET_<UPPERCASE_UNDERSCORE_RUST_TRIPLE>_LINKER`.
        # # They can also be set in `.cargo/config.toml` instead.
        # # See: https://doc.rust-lang.org/cargo/reference/config.html#target
        # CARGO_TARGET_AARCH64_UNKNOWN_LINUX_GNU_RUNNER = "qemu-aarch64";
        # CARGO_TARGET_AARCH64_UNKNOWN_LINUX_GNU_LINKER = "${pkgs.stdenv.cc.targetPrefix}cc";
      };
    };
}
