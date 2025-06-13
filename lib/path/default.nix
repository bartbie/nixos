{
  lib,
  final,
  self,
  ...
}: {
  toDir = x: final.condApply (!lib.pathIsDirectory x) builtins.dirOf x;
}
