{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    naersk = {
      url = "github:nix-community/naersk";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # optional
    flake-parts.url = "github:hercules-ci/flake-parts";

    systems.url = "github:nix-systems/default";

    # auto-import nix files
    # import-tree.url = "github:vic/import-tree";
  };

  outputs = {
    nixpkgs,
    rust-overlay,
    naersk,
    ...
  } @ inputs:
    inputs.flake-parts.lib.mkFlake {inherit inputs;} {
      systems = import inputs.systems;
      perSystem = {
        system,
        pkgs,
        ...
      }: let
        toolchain = pkgs.rust-bin.stable.latest.default.override (p: {
          extensions = p.extensions ++ ["rust-src"];
        });

        naersk' = pkgs.callPackage naersk {
          cargo = toolchain;
          rustc = toolchain;
        };
      in {
        _module.args.pkgs = import nixpkgs {
          inherit system;
          overlays = [(import rust-overlay)];
        };

        packages.default = naersk'.buildPackage {
          src = ./.;
        };

        devShells.default = pkgs.mkShell {
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
          depsBuildBuild = [];
          # Run-time dependencies. build = your-machine, host = target = aarch64
          # Usually are libraries to be linked.
          buildInputs = [];
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
    };
}
