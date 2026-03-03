{ lib, ... }:
{
  checkAssertions =
    assertions:
    let
      failed = lib.filter (a: !a.assertion) assertions;
    in
    if failed == [ ] then
      true
    else
      builtins.throw ''
        ${builtins.toString (builtins.length failed)} assertion(s) failed:
        ${lib.concatMapStringsSep "\n" (a: "  - ${a.message}") failed}
      '';

  propagateAssertions = lists: lists |> lib.flatten |> lib.concatMap (i: i.assertions or [ ]);
}
