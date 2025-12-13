# A generalization of Nixpkgs's `strings-with-deps.nix`.
#
# The main differences from the Nixpkgs version are
#
#  - not specific to strings, i.e., any payload is OK,
#
#  - the addition of the function `entryBefore` indicating a "wanted by" relationship.
{
  lib,
  self,
  ...
}: let
  inherit
    (lib)
    types
    mkOption
    mkIf
    mkOrder
    ;

  makeProperty = {
    type,
    extraCheck ? _: true,
    customMap ? null,
    empty ? {},
    emptyOf ? x: x,
  }: let
    _type = type;
    mkWith = x: {inherit _type;} // x;
    check = val: extraCheck val;
    hasTag = val: val ? _type && val._type == _type;
  in {
    inherit mkWith check hasTag;
    tag = _type;
    is = val: hasTag val && extraCheck val;
    strip = prop: builtins.removeAttrs prop _type;

    empty = mkWith empty;
    emptyOf = z: mkWith (emptyOf z);

    mk = content: {inherit _type content;};
    get = prop:
      assert prop ? _type && prop._type == _type;
        prop.content;

    map =
      if customMap != null
      then customMap
      else fn: prop: prop // {content = fn prop.content;};
  };

  isNotProperty = l: v: builtins.all (x: !(x.hasTag v)) l;

  Entry = makeProperty {
    type = "dag-entry";
    extraCheck = e: e ? data && e ? after && e ? before;
    customMap = fn: {
      data,
      before,
      after,
    }: {
      inherit before after;
      data = fn data;
    };
    empty = {
      before = [];
      after = [];
      data = null;
    };
  };

  stripEntries = x:
    assert builtins.isAttrs x;
      x
      |> builtins.mapAttrs (
        n: v:
          if isEntry v
          then v.data
          else v
      );

  entryBetween = before: after: data:
    assert builtins.isList before;
    assert builtins.isList after;
    assert builtins.all builtins.isString before;
    assert builtins.all builtins.isString after;
      Entry.mkWith {inherit data before after;};
  # Create a DAG entry with no particular dependency information.
  entryAnywhere = entryBetween [] [];

  entryAfter = entryBetween [];
  entryBefore = before: entryBetween before [];

  checkDag = content: builtins.isAttrs content && builtins.all Entry.is (builtins.attrValues content);

  Dag = makeProperty {
    type = "dag";
    extraCheck = {content ? {}, ...}: checkDag content;
    empty = {content = {};};
    customMap = fn: {content ? {}, ...}: Dag.mk (builtins.mapAttrs fn content);
  };

  mkDag = x:
    assert builtins.isAttrs x;
      Dag.mk x;
  # Applies a function to each element of the given DAG.
  mapDag = Dag.map;

  maybeConvert = {
    value,
    priority ? null,
    ...
  }:
    if Entry.is value
    then value
    else
      entryAnywhere (
        if priority != null
        then mkOrder priority value
        else value
      );

  maybeConvertDefs = builtins.map (def: {
    inherit (def) file;
    value = maybeConvert def;
  });

  dagEntryOf = elemType: let
    submoduleType = types.submodule (
      {name, ...}: {
        options = {
          data = mkOption {type = elemType;};
          after = mkOption {type = with types; listOf str;};
          before = mkOption {type = with types; listOf str;};
          _type = mkOption {
            type = types.enum [Entry.tag];
            default = Entry.tag;
          };
        };
        config = mkIf (elemType.name == "submodule") {
          data._module.args.dagName = name;
        };
      }
    );
    # CORRECTNESS:
    # snapshots require correct order. otherwise could use uniqueStrings
    uniq = lib.lists.unique;
  in
    lib.mkOptionType {
      name = "dagEntryOf";
      description = "DAG entry of ${elemType.description}";
      merge = loc: defs:
        submoduleType.merge loc (maybeConvertDefs defs)
        |> ({
            after,
            before,
            ...
          } @ rest:
            rest
            // {
              after = uniq after;
              before = uniq before;
            });
    };

  # A directed acyclic graph of some inner type.
  #
  # Note, if the element type is a submodule then the `name` argument
  # will always be set to the string "data" since it picks up the
  # internal structure of the DAG values. To give access to the
  # "actual" attribute name a new submodule argument is provided with
  # the name `dagName`.
  dagOf = elemType: let
    attrEquivalent = types.attrsOf (dagEntryOf elemType);
    name = "dagOf";
  in
    lib.mkOptionType {
      inherit name;
      description = "DAG of ${elemType.description}";
      inherit
        (attrEquivalent)
        emptyValue
        # simple check just to cover most egregious errors
        check
        ;
      merge = loc: defs:
        defs
        |> builtins.map ({
          file,
          value,
          ...
        }: {
          inherit file;
          value =
            if isDag value
            then value.content or {}
            else value;
        })
        |> attrEquivalent.merge loc
        |> mkDag;
      getSubOptions = prefix: elemType.getSubOptions (prefix ++ ["<name>"]);
      getSubModules = elemType.getSubModules;
      substSubModules = m: dagOf (elemType.substSubModules m);
      functor =
        (lib.defaultFunctor name)
        // {
          wrapped = elemType;
        };
      nestedTypes.elemType = elemType;
    };

  # A directed acyclic graph of some submodule type.
  dagSubmodule = submoduleDef: let
    submoduleType = types.submodule submoduleDef;

    mapDefs = fn: (builtins.map (
      def: {
        inherit (def) file;
        value = fn def.value;
      }
    ));
  in
    lib.mkOptionType {
      name = "dagSubmodule";
      description = "DAG submodule of ${submoduleType.description}";
      merge = loc: defs: let
        # merge all definitions as entries without type-checking.
        # merges entries metadata properly and avoids incorrect attrs merging
        merged-metadata =
          defs
          |> (mapDefs (builtins.mapAttrs (_: v:
            if isEntry v
            then v
            else entryAnywhere v)))
          |> (configSubmodule {}).merge loc;

        # merge all definitions as submodule with type-checking
        # walks the defs values and extracts data from entries,
        # making it invisible to underlying submodule type
        merged-data =
          defs
          |> mapDefs (
            let
              walk = def:
                if builtins.isAttrs def
                then
                  def
                  |> lib.mapAttrsRecursiveCond
                  (as: !(isEntry as))
                  (path: entry:
                    if isEntry entry
                    then walk entry.data
                    else entry)
                else def;
            in
              walk
          )
          |> submoduleType.merge loc;
      in
        # combine entries metadata with their data
        merged-metadata
        |> builtins.mapAttrs (n: v: v // {data = merged-data.${n};})
        |> mkDag;
    };

  submoduleTypeWith = {
    dag ? false,
    config ? false,
  }: submoduleDef:
    (
      if dag
      then dagSubmodule
      else types.submodule
    )
    {
      freeformType = lib.mkIf config freeformConfigType;
      imports = lib.flatten submoduleDef;
    };

  dagConfigSubmodule = submoduleTypeWith {
    dag = true;
    config = true;
  };

  # Given a list of entries, this function places them in order within the DAG.
  # Each entry is labeled "${tag}-${entry index}" and other DAG entries can be
  # added with 'before' or 'after' referring these indexed entries.
  #
  # The entries as a whole can be given a relation to other DAG nodes. All
  # generated nodes are then placed before or after those dependencies.
  entriesBetween = tag: let
    go = i: before: after: entries:
      assert builtins.isList before;
      assert builtins.isList after;
      assert builtins.isList entries;
      assert builtins.all builtins.isString before;
      assert builtins.all builtins.isString after; let
        name = "${tag}-${toString i}";
      in
        if entries == []
        then {}
        else if builtins.length entries == 1
        then {
          "${name}" = entryBetween before after (builtins.head entries);
        }
        else
          {
            "${name}" = entryAfter after (builtins.head entries);
          }
          // go (i + 1) before [name] (builtins.tail entries);
  in
    go 0;

  # Takes an attribute set containing entries built by entryAnywhere,
  # entryAfter, and entryBefore to a topologically sorted list of
  # entries.
  #
  # Internally this function uses the `toposort` function in
  # `<nixpkgs/lib/lists.nix>` and its value is accordingly.
  #
  # Specifically, the result on success is
  #
  #    { result = [ { name = ?; data = ?; } … ] }
  #
  # For example
  #
  #    nix-repl> topoSort {
  #                a = entryAnywhere "1";
  #                b = entryAfter [ "a" "c" ] "2";
  #                c = entryBefore [ "d" ] "3";
  #                d = entryBefore [ "e" ] "4";
  #                e = entryAnywhere "5";
  #              } == {
  #                result = [
  #                  { data = "1"; name = "a"; }
  #                  { data = "3"; name = "c"; }
  #                  { data = "2"; name = "b"; }
  #                  { data = "4"; name = "d"; }
  #                  { data = "5"; name = "e"; }
  #                ];
  #              }
  #    true
  #
  # And the result on error is
  #
  #    {
  #      cycle = [ { after = ?; name = ?; data = ? } … ];
  #      loops = [ { after = ?; name = ?; data = ? } … ];
  #    }
  #
  # For example
  #
  #    nix-repl> topoSort {
  #                a = entryAnywhere "1";
  #                b = entryAfter [ "a" "c" ] "2";
  #                c = entryAfter [ "d" ] "3";
  #                d = entryAfter [ "b" ] "4";
  #                e = entryAnywhere "5";
  #              } == {
  #                cycle = [
  #                  { after = [ "a" "c" ]; data = "2"; name = "b"; }
  #                  { after = [ "d" ]; data = "3"; name = "c"; }
  #                  { after = [ "b" ]; data = "4"; name = "d"; }
  #                ];
  #                loops = [
  #                  { after = [ "a" "c" ]; data = "2"; name = "b"; }
  #                ];
  #              }
  #    true
  topoSort = let
    dagBefore = dag: name:
      assert !(dag ? _type); # assert normalized is passed
      
        dag
        |> lib.filterAttrs (n: v: builtins.elem name v.before)
        |> builtins.attrNames;
    before = a: b: builtins.elem a.name b.after;
  in
    dag:
      assert isDagLike dag; let
        normalized =
          if isDagNormalized dag
          then dag.content or {}
          else if isDag dag
          then
            dag.content or {}
            |> builtins.mapAttrs (_: v:
              if v ? value
              then maybeConvert v
              else maybeConvert {value = v;})
          else dag;
        sorted =
          normalized
          |> lib.mapAttrsToList (n: v: {
            name = n;
            data = v.data;
            after = v.after ++ dagBefore normalized n;
          })
          |> lib.toposort before;
      in
        if sorted ? result
        then {
          result = sorted.result |> builtins.map (v: {inherit (v) name data;});
        }
        else sorted;

  entriesAnywhere = tag: entriesBetween tag [] [];
  entriesAfter = tag: entriesBetween tag [];
  entriesBefore = tag: before: entriesBetween tag before [];

  Append = makeProperty {
    type = "append";
    empty = {contents = [];};
    emptyOf = contents: assert builtins.isList contents; {inherit contents;};
    extraCheck = {contents ? [], ...}: builtins.isList contents;
    customMap = fn: {contents ? [], ...}: Append.mkWith {contents = builtins.map fn contents;};
  };

  mkAppend = contents:
    assert builtins.isList contents;
      Append.mkWith {inherit contents;};

  appendOf = elemType: let
    listEquivalent = types.listOf elemType;
    name = "appendOf";
  in
    lib.mkOptionType {
      inherit name;
      description = "Append of ${elemType.description}";
      inherit
        (listEquivalent)
        emptyValue
        # simple check just to cover most egregious errors
        check
        ;
      merge = loc: defs:
        defs
        |> builtins.map ({
          file,
          value,
          ...
        }: {
          inherit file;
          value =
            if isAppend value
            then value.contents or []
            else value;
        })
        |> listEquivalent.merge loc
        |> mkAppend;
      getSubOptions = prefix: elemType.getSubOptions (prefix ++ ["<name>"]);
      getSubModules = elemType.getSubModules;
      substSubModules = m: appendOf (elemType.substSubModules m);
      functor =
        (lib.defaultFunctor name)
        // {
          wrapped = elemType;
        };
      nestedTypes.elemType = elemType;
    };

  getType = value:
    if builtins.isAttrs value
    then
      if lib.strings.isStringLike value
      then "stringCoercibleSet"
      else if isDag value
      then Dag.tag
      else if Entry.is value
      then Entry.tag
      else if isAppend value
      then Append.tag
      else builtins.typeOf value
    else builtins.typeOf value;

  groupByType = builtins.groupBy getType;

  freeformConfigType = lib.mkOptionType {
    name = "freeformConfig";
    check = _: true;
    merge = loc: defs: let
      # Returns the common type of all definitions, throws an error if they
      # don't have the same type
      commonType =
        builtins.foldl' (
          type: def:
            if getType def.value == type
            then type
            else
              throw "The option `${lib.options.showOption loc}' has conflicting option types:${lib.options.showDefs [
                (builtins.head defs)
                def
              ]}\n"
        ) (getType (builtins.head defs).value)
        defs;

      mergeFunction =
        {
          # merge our properties correctly
          ${Dag.tag} = (dagOf freeformConfigType).merge;
          ${Entry.tag} = (dagEntryOf freeformConfigType).merge;
          ${Append.tag} = (appendOf freeformConfigType).merge;
          # Recursively merge attribute sets
          set = (types.attrsOf freeformConfigType).merge;
          # This is the type of packages, only accept a single definition
          stringCoercibleSet = lib.options.mergeOneOption;
          lambda = loc: defs:
            throw "Config attrset can't store functions!\noption: `${lib.options.showOption loc}'\noption definitions: ${lib.options.showDefs defs}\n";

          # lambda = loc: defs: arg:
          #   freeformConfigType.merge (loc ++ ["<function body>"]) (
          #     map (def: {
          #       file = def.file;
          #       value = def.value arg;
          #     })
          #     defs
          #   );
          list = (types.listOf freeformConfigType).merge;
          # Otherwise fall back to only allowing all equal definitions
        }.${
          commonType
        } or lib.mergeEqualOption;
    in
      mergeFunction loc defs;
  };

  configSubmodule = mod:
    types.submodule ({
        freeformType = freeformConfigType;
      }
      // mod);

  isDag = x: Dag.hasTag x;
  isDagNormalized = Dag.is;
  isDagLike = x: isDag x || checkDag x;
  isEntry = Entry.is;
  isAppend = x: Append.hasTag x;
  isAppendNormalized = Append.is;

  _tests = let
    evalType = type: val:
      lib.evalModules {
        modules = [
          {
            options.optionForTypeTest = lib.mkOption {
              inherit type;
            };
            config.optionForTypeTest = val;
          }
        ];
      }
      |> (x: x.config.optionForTypeTest);

    evalType' = type: defs:
      lib.evalModules {
        modules =
          [
            {
              options.optionForTypeTest = lib.mkOption {
                inherit type;
              };
            }
          ]
          ++ (defs
            |> builtins.map (
              d: {
                config.optionForTypeTest = d;
              }
            ));
      }
      |> (x: x.config.optionForTypeTest);
    evalFreeform = defs:
      lib.evalModules {
        modules =
          [
            {
              options.optionForTypeTest = lib.mkOption {
                type = types.submodule {
                  freeformType = freeformConfigType;
                };
              };
            }
          ]
          ++ (defs
            |> lib.flatten
            |> builtins.map (
              d: {
                config.optionForTypeTest = d;
              }
            ));
      }
      |> (x: x.config.optionForTypeTest);

    evalTest = mods:
      lib.evalModules {
        modules = lib.flatten [
          {
            options.result = lib.mkOption {
              type = types.submodule {
                freeformType = freeformConfigType;
              };
            };
          }
          mods
        ];
      }
      |> (x: x.config.result);
  in {
    "test - dagOfEntry convert works" = {
      expr = evalType (dagEntryOf types.str) "1";
      expected = entryAnywhere "1";
    };
    "test - dagOfEntry inside dagOf works" = {
      expr = evalType (dagOf types.str) {
        a = entryAnywhere "1";
      };
      expected = mkDag {
        a = entryAnywhere "1";
      };
    };
    "test - dagOfEntry inside dagOf convert works" = {
      expr = evalType (dagOf types.str) {
        a = "1";
      };
      expected = mkDag {
        a =
          entryAnywhere "1";
      };
    };
    "test - appendOf works" = {
      expr = evalType (appendOf types.str) [
        "a"
        "b"
      ];
      expected = mkAppend [
        "a"
        "b"
      ];
    };
    "test - mkOrder in list test" = {
      expr = evalType' (types.listOf types.str) [
        [(lib.mkAfter "last")]
        ["second-last"]
        [(lib.mkBefore "third")]
        ["second"]
        [(lib.mkBefore "first")]
      ];
      expected = [
        "first"
        "second"
        "third"
        "second-last"
        "last"
      ];
    };
    "test - appendOf dagOf works" = {
      expr = evalType (appendOf (dagOf types.str)) [
        {
          a = entryAnywhere "1";
          b = entryAfter ["a" "c"] "2";
        }
        {
          c = entryBefore ["d"] "3";
          d = entryBefore ["e"] "4";
          e = entryAnywhere "5";
          f = "5";
        }
      ];
      expected = mkAppend [
        (mkDag {
          a = entryAnywhere "1";
          b = entryAfter ["a" "c"] "2";
        })
        (mkDag {
          c = entryBefore ["d"] "3";
          d = entryBefore ["e"] "4";
          e = entryAnywhere "5";
          f = entryAnywhere "5";
        })
      ];
    };
    "test - dagOf appendOf works" = {
      expr = evalType (dagOf (appendOf types.str)) {
        a = entryAnywhere ["1"];
        b = entryAfter ["a" "c"] ["2"];
        c = entryBefore ["d"] ["3"];
        d = entryBefore ["e"] ["4"];
        e = entryAnywhere ["5" "3" "2"];
        f = ["5"];
      };
      expected = mkDag {
        a = entryAnywhere (mkAppend ["1"]);
        b = entryAfter ["a" "c"] (mkAppend ["2"]);
        c = entryBefore ["d"] (mkAppend ["3"]);
        d = entryBefore ["e"] (mkAppend ["4"]);
        e = entryAnywhere (mkAppend ["5" "3" "2"]);
        f = entryAnywhere (mkAppend ["5"]);
      };
    };
    "test - freeformType works singular no-DAG" = {
      expr = evalFreeform {
        a = entryAnywhere ["1"];
        b = entryAfter ["a" "c"] ["2"];
        c = entryBefore ["d"] ["3"];
        d = entryBefore ["e"] ["4"];
        e = entryAnywhere ["5" "3" "2"];
        f = ["5"];
      };
      expected = {
        a = entryAnywhere ["1"];
        b = entryAfter ["a" "c"] ["2"];
        c = entryBefore ["d"] ["3"];
        d = entryBefore ["e"] ["4"];
        e = entryAnywhere ["5" "3" "2"];
        # freeform type does NOT identify parent as DAG, f stays the same
        f = ["5"];
      };
    };
    "test - freeformType works singular DAG" = {
      expr = evalFreeform {
        shouldBeDag = mkDag {
          a = entryAnywhere ["1"];
          b = entryAfter ["a" "c"] ["2"];
          c = entryBefore ["d"] ["3"];
          d = entryBefore ["e"] ["4"];
          e = entryAnywhere ["5" "3" "2"];
          f = ["5"];
        };
      };
      expected = {
        shouldBeDag = mkDag {
          a = entryAnywhere ["1"];
          b = entryAfter ["a" "c"] ["2"];
          c = entryBefore ["d"] ["3"];
          d = entryBefore ["e"] ["4"];
          e = entryAnywhere ["5" "3" "2"];
          # freeform type identifies parent as DAG, f gets normalized
          f = entryAnywhere ["5"];
        };
      };
    };
    "test - mkDag" = {
      expr = mkDag {
        a = entryAnywhere ["1"];
      };
      expected = {
        _type = Dag.tag;
        content = {
          a = entryAnywhere ["1"];
        };
      };
    };
    "test - isDag" = {
      expr = isDag (mkDag {
        a = entryAnywhere ["1"];
        b = entryAfter ["a" "c"] ["2"];
        c = entryBefore ["d"] ["3"];
        d = entryBefore ["e"] ["4"];
        e = entryAnywhere ["5" "3" "2"];
        f = ["5"];
      });
      expected = true;
    };
    "test - isDagLike true" = {
      expr = isDagLike {
        a = entryAnywhere ["1"];
        b = entryAfter ["a" "c"] ["2"];
        c = entryBefore ["d"] ["3"];
        d = entryBefore ["e"] ["4"];
        e = entryAnywhere ["5" "3" "2"];
        f = entryAnywhere ["5"];
      };
      expected = true;
    };
    "test - isDagLike false" = {
      expr = isDagLike {
        a = entryAnywhere ["1"];
        b = entryAfter ["a" "c"] ["2"];
        c = entryBefore ["d"] ["3"];
        d = entryBefore ["e"] ["4"];
        e = entryAnywhere ["5" "3" "2"];
        f = ["5"];
      };
      expected = false;
    };
    "test - freeformType works multiple DAG" = {
      expr = let
        data =
          [
            (mkDag {
              a = entryAnywhere ["1"];
              b = entryAfter ["a" "c"] ["2"];
              c = entryBefore ["d"] ["3"];
            })
            (mkDag {
              d = entryBefore ["e"] ["4"];
              e = entryAnywhere ["5" "3" "2"];
              f = ["5"];
            })
          ]
          |> builtins.map (x: assert lib.assertMsg (x ? _type) "no _type"; x)
          |> builtins.map (foo: {inherit foo;});
      in
        evalFreeform data;
      expected = {
        foo = mkDag {
          a = entryAnywhere ["1"];
          b = entryAfter ["a" "c"] ["2"];
          c = entryBefore ["d"] ["3"];
          d = entryBefore ["e"] ["4"];
          e = entryAnywhere ["5" "3" "2"];
          # freeform type identifies parent as DAG, f gets normalized
          f = entryAnywhere ["5"];
        };
      };
    };
    "test - freeformType errors on explicit DAG and unnormalized DAG" = {
      expr = let
        data = [
          (mkDag {
            a = entryAnywhere ["1"];
            b = entryAfter ["a" "c"] ["2"];
            c = entryBefore ["d"] ["3"];
          })
          {
            d = entryBefore ["e"] ["4"];
            e = entryAnywhere ["5" "3" "2"];
            f = ["5"];
          }
        ];
      in
        (builtins.tryEval (evalFreeform data)).success;
      expected = false;
    };

    "test - freeformType works Append" = let
      data =
        (mkAppend [
          {
            a = ["1"];
            b = ["2"];
            c = ["3"];
          }
          {
            d = ["4"];
            e = ["5" "3" "2"];
            f = ["5"];
          }
        ])
        |> (x: assert lib.assertMsg (x ? _type) "no _type"; x);
    in {
      expr = evalFreeform [
        {
          foo = data;
        }
      ];
      expected = {
        foo = data;
      };
    };
    "test - freeformType works multiple Append" = {
      expr = let
        data =
          [
            (mkAppend [
              {
                a = ["1"];
                b = ["2"];
              }
              {
                c = ["3"];
                d = ["4"];
              }
            ])
            (mkAppend [
              {
                e = ["5" "3" "2"];
              }
              {
                f = ["5"];
              }
            ])
          ]
          |> builtins.map (x: assert lib.assertMsg (x ? _type) "no _type"; x)
          |> builtins.map (foo: {inherit foo;});
      in
        evalFreeform data;
      expected = {
        foo = mkAppend [
          {
            a = ["1"];
            b = ["2"];
          }
          {
            c = ["3"];
            d = ["4"];
          }
          {
            e = ["5" "3" "2"];
          }
          {
            f = ["5"];
          }
        ];
      };
    };
    "test - freeformType + options works with appendOf dagOf" = {
      expr = evalTest [
        ({config, ...}: {
          options.result.foo = lib.mkOption {
            type = appendOf (dagOf (types.listOf types.str));
          };
        })

        {
          result.foo = [
            {
              a = entryAnywhere ["1"];
              b = entryAfter ["a" "c"] ["2"];
            }
            {
              c = entryBefore ["d"] ["3"];
            }
          ];
        }
        {
          result.foo = [
            {
              d = entryBefore ["e"] ["4"];
              e = entryAnywhere ["5" "3" "2"];
            }
            {
              f = ["5"];
            }
          ];
        }
        {
          result.foo = [
            {e = entryAnywhere ["3" "2"];}
          ];
        }
      ];
      expected = {
        foo = mkAppend [
          (mkDag {
            a = entryAnywhere ["1"];
            b = entryAfter ["a" "c"] ["2"];
          })
          (mkDag {
            c = entryBefore ["d"] ["3"];
          })
          (mkDag {
            d = entryBefore ["e"] ["4"];
            e = entryAnywhere ["5" "3" "2"];
          })
          (mkDag {
            f = entryAnywhere ["5"];
          })
          (mkDag {
            e = entryAnywhere ["3" "2"];
          })
        ];
      };
    };
    "test - freeformType + options works with dagOf appendOf" = {
      expr = evalTest [
        ({config, ...}: {
          options.result.foo = lib.mkOption {
            type = dagOf (appendOf types.str);
          };
        })
        {
          result.foo = {
            a = entryAnywhere ["1"];
            b = entryAfter ["a" "c"] ["2"];
            c = entryBefore ["d"] ["3"];
          };
        }
        {
          result.foo = {
            a = entryAnywhere ["1"];
            d = entryBefore ["e"] ["4"];
            e = entryAnywhere ["5"];
            f = ["5"];
          };
        }
        {
          result.foo = {
            d = entryAfter ["f"] (lib.mkAfter ["X"]);
            e = entryAnywhere (lib.mkAfter ["3" "2"]);
          };
        }
      ];
      expected = {
        foo = mkDag {
          a = entryAnywhere (mkAppend ["1" "1"]);
          b = entryAfter ["a" "c"] (mkAppend ["2"]);
          c = entryBefore ["d"] (mkAppend ["3"]);
          d = entryBetween ["e"] ["f"] (mkAppend ["4" "X"]);
          e = entryAnywhere (mkAppend ["5" "3" "2"]);
          f = entryAnywhere (mkAppend ["5"]);
        };
      };
    };
    "test - dagEntryOf merges after before defs" = {
      expr = evalType' (dagOf (types.listOf types.str)) [
        {
          a = entryAnywhere ["1"];
          b = entryAfter ["a" "c"] ["2"];
          c = entryBefore ["d"] ["3"];
        }
        {
          d = entryBefore ["e"] ["4"];
          e = entryAfter ["f"] ["5"];
          f = entryAnywhere ["5"];
        }
        {
          d = entryAfter ["a"] ["X"];
          e = entryAfter ["c"] ["Z"];
        }
      ];
      expected = mkDag {
        a = entryAnywhere ["1"];
        b = entryAfter ["a" "c"] ["2"];
        c = entryBefore ["d"] ["3"];
        f = entryAnywhere ["5"];
        d = entryBetween ["e"] ["a"] ["4" "X"];
        e = entryAfter ["f" "c"] ["5" "Z"];
      };
    };
    "test - dagEntryOf appendOf merge" = {
      expr = evalType' (dagEntryOf (appendOf types.int)) [
        (entryAnywhere [1 2])
        (entryAnywhere [3 4])
      ];
      expected = entryAnywhere (mkAppend [1 2 3 4]);
    };
    "test - topoSort dagOf" = {
      expr =
        evalType (dagOf (appendOf types.int)) {
          a = entryAfter ["b"] [1 2];
          b = entryAnywhere [3 4];
        }
        |> topoSort
        |> (x: x.result);
      expected = [
        {
          name = "b";
          data = mkAppend [3 4];
        }
        {
          name = "a";
          data = mkAppend [1 2];
        }
      ];
    };
    "test dag-module" = let
      dag = self;
      typed = type: lib.mkOption {inherit type;};
      mkMonitor = output: at:
        at
        |> builtins.mapAttrs (_: dag.entryAfter ["output"])
        |> (x: x // {inherit output;});
      module = {
        options.monitorv2 = typed (dag.appendOf (dagSubmodule {
          freeformType = freeformConfigType;
          options.scale = typed (types.numbers.positive);
        }));
        config.monitorv2 = [
          (mkMonitor "test" {
            mode = "preferred";
            position = "auto";
            scale = 1;
          })
        ];
      };
      eval = x:
        lib.evalModules {
          modules = [
            {_module.freeformType = freeformConfigType;}
            x
          ];
        };
    in {
      expr = (eval module).config.monitorv2;
      expected = mkAppend [
        (mkDag {
          output = entryAnywhere "test";
          mode = entryAfter ["output"] "preferred";
          position = entryAfter ["output"] "auto";
          scale = entryAfter ["output"] 1;
        })
      ];
    };
    "test submoduleTypeWith" = let
      dag = self;
      typed = type: lib.mkOption {inherit type;};
      mkMonitor = output: at:
        at
        |> builtins.mapAttrs (_: dag.entryAfter ["output"])
        |> (x: x // {inherit output;});
      module = {
        options.monitor = typed (submoduleTypeWith {
            config = true;
            dag = true;
          } {
            options.scale = typed (types.numbers.positive);
          });
        config.monitor = mkMonitor "test" {
          mode = "preferred";
          position = "auto";
          scale = 1;
        };
      };
      eval = x: lib.evalModules {modules = [x];};
    in {
      expr = (eval module).config.monitor;
      expected = mkDag {
        output = entryAnywhere "test";
        mode = entryAfter ["output"] "preferred";
        position = entryAfter ["output"] "auto";
        scale = entryAfter ["output"] 1;
      };
    };
  };
in {
  inherit
    entryBetween
    entryAnywhere
    entryAfter
    entryBefore
    mkDag
    mapDag
    topoSort
    dagOf
    dagEntryOf
    entriesBetween
    entriesAnywhere
    entriesAfter
    entriesBefore
    isDag
    isDagLike
    isDagNormalized
    isEntry
    mkAppend
    isAppend
    appendOf
    getType
    groupByType
    freeformConfigType
    configSubmodule
    dagSubmodule
    dagConfigSubmodule
    submoduleTypeWith
    ;

  _runTests = tests: lib.runTests (_tests // {inherit tests;});
  _tests = lib.runTests _tests;

  x = {
    a = entryAnywhere "1";
    b = entryAfter ["a" "c"] "2";
    c = entryBefore ["d"] "3";
    d = entryBefore ["e"] "4";
    e = entryAnywhere "5";
    f = "5";
  };

  tag = {
    dag = Dag.tag;
    append = Append.tag;
    entry = Entry.tag;
  };
}
