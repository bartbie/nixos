{ lib, ... }:
{
  flake.modules = {
    nixos.pc = { };
    darwin.base = { };
  };
}
