{ lib, ... }:
{
  toDir = x: if !lib.pathIsDirectory x then builtins.dirOf x else x;
}
