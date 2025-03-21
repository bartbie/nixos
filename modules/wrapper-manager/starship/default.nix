{
  pkgs,
  lib,
  ...
}: let
  inherit (pkgs.formats.toml {}) generate;
  withCount = s: "${s}\${count}";
  settings = {
    add_newline = false;
    time = {
      disabled = false;
    };
    git_status = {
      conflicted = withCount "=";
      ahead = withCount "⇡";
      behind = withCount "⇣";
      diverged = withCount "⇕";
      up_to_date = "";
      untracked = withCount "?";
      stashed = withCount "$";
      modified = withCount "!";
      staged = withCount "+";
      renamed = withCount "»";
      deleted = withCount "✘";
    };
    aws.symbol = "  ";
    buf.symbol = " ";
    c.symbol = " ";
    conda.symbol = " ";
    crystal.symbol = " ";
    dart.symbol = " ";
    directory.read_only = " 󰌾";
    docker_context.symbol = " ";
    elixir.symbol = " ";
    elm.symbol = " ";
    fennel.symbol = " ";
    fossil_branch.symbol = " ";
    git_branch.symbol = " ";
    golang.symbol = " ";
    guix_shell.symbol = " ";
    haskell.symbol = " ";
    haxe.symbol = " ";
    hg_branch.symbol = " ";
    hostname.ssh_symbol = " ";
    java.symbol = " ";
    julia.symbol = " ";
    kotlin.symbol = " ";
    lua.symbol = " ";
    memory_usage.symbol = "󰍛 ";
    meson.symbol = "󰔷 ";
    nim.symbol = "󰆥 ";
    nix_shell.symbol = " ";
    nodejs.symbol = " ";
    ocaml.symbol = " ";
    package.symbol = "󰏗 ";
    perl.symbol = " ";
    php.symbol = " ";
    pijul_channel.symbol = " ";
    python.symbol = " ";
    rlang.symbol = "󰟔 ";
    ruby.symbol = " ";
    rust.symbol = "🦀 ";
    # rust.symbol = "󱘗 ";
    scala.symbol = " ";
    swift.symbol = " ";
    zig.symbol = " ";
    os.symbols = {
      Alpaquita = " ";
      Alpine = " ";
      # AlmaLinux = " ";
      Amazon = " ";
      Android = " ";
      Arch = " ";
      Artix = " ";
      CentOS = " ";
      Debian = " ";
      DragonFly = " ";
      Emscripten = " ";
      EndeavourOS = " ";
      Fedora = " ";
      FreeBSD = " ";
      Garuda = "󰛓 ";
      Gentoo = " ";
      HardenedBSD = "󰞌 ";
      Illumos = "󰈸 ";
      Kali = " ";
      Linux = " ";
      Mabox = " ";
      Macos = " ";
      Manjaro = " ";
      Mariner = " ";
      MidnightBSD = " ";
      Mint = " ";
      NetBSD = " ";
      NixOS = " ";
      OpenBSD = "󰈺 ";
      openSUSE = " ";
      OracleLinux = "󰌷 ";
      Pop = " ";
      Raspbian = " ";
      Redhat = " ";
      RedHatEnterprise = " ";
      RockyLinux = " ";
      Redox = "󰀘 ";
      Solus = "󰠳 ";
      SUSE = " ";
      Ubuntu = " ";
      Unknown = " ";
      Void = " ";
      Windows = "󰍲 ";
    };
  };
in {
  wrappers.starship = {
    arg0 = lib.getExe' pkgs.starship "starship";
    env.STARSHIP_CONFIG.value = "${generate "starship.toml" settings}";
  };
}
