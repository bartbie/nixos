{
  lib,
  final,
  ...
}:
let
  inherit (lib) types;
  inherit (final) dag;

  # groupByAttrs = pred: label1: label2: attrs:
  #   assert builtins.isAttrs attrs;
  #   assert builtins.isString label1;
  #   assert builtins.isString label2; let
  #     l1 =
  #       attrs
  #       |> lib.filterAttrs pred;
  #   in {
  #     ${label1} = l1;
  #     ${label2} = builtins.removeAttrs attrs (builtins.attrNames l1);
  #   };

  #   {
  #     $huj = 1;
  #     dupa = 2;
  #   };

  #   [
  #     {name = "$huj"; value = 1;}
  #     {name = "dupa"; value = 2;}
  #   ];

  # {
  #   $ = [{name="$huj";value=1;}]
  #   rest = [{name="dupa";value=2;}]
  # }

  join =
    list:
    let
      x = builtins.filter (x: x != "") list;
    in
    if x == [ ] then "" else lib.join "\n" x;

  groupByAttrs' =
    fn: attrs:
    attrs
    |> lib.attrsToList
    |> builtins.groupBy (
      {
        name,
        value,
      }:
      fn name value
    )
    |> builtins.mapAttrs (_group: builtins.listToAttrs);

  evalConfig' =
    configModules:
    lib.evalModules {
      modules = lib.flatten [
        configModules
        {
          options.output = lib.mkOption {
            type = dag.submoduleTypeWith {
              dag = false;
              config = true;
            } { };
          };
        }
      ];
    };

  evalConfig = m: (evalConfig' m).config.output;

  configToHyprconf =
    {
      config,
      indentLevel ? 0,
      indentString ? "  ",
      importantPrefixes ? [ "$" ],
    }:
    let
      INDENT = indentString;
      indentOf = n: (builtins.genList (_: INDENT) n) |> lib.join "";
      incIndentBy = n: ind: ind + (indentOf n);
      incIndent = ind: ind + INDENT;

      isVal = x: !(builtins.isAttrs x) && !(builtins.isList x);
      isListOf =
        check: x:
        assert builtins.isFunction check;
        builtins.isList x && builtins.all check x;

      attrsOf =
        check: x:
        assert builtins.isFunction check;
        builtins.isAttrs x && (builtins.all check (builtins.attrValues x));

      isField = x: isVal x || isListOf isVal x;
      isFields = attrsOf isField;

      isSection = x: !(isField x);

      groupSectionsFieldsAttrs =
        x:
        assert builtins.isAttrs x;
        x
        |> groupByAttrs' (_: v: if isSection v then "sections" else "fields")
        |> (
          {
            sections ? { },
            fields ? { },
          }:
          {
            inherit sections fields;
          }
        );

      groupSectionsFieldsList =
        x:
        assert builtins.isList x;
        x
        |> builtins.groupBy (v: if isSection v then "sections" else "fields")
        |> (
          {
            sections ? [ ],
            fields ? [ ],
          }:
          {
            inherit sections fields;
          }
        );

      # renders inside of fields as lines of k=v
      renderFields =
        indent: fields:
        assert lib.assertMsg (isFields fields) (lib.generators.toPretty { } fields);
        assert isFields fields;
        let
          renderFields' = lib.generators.toKeyValue {
            listsAsDuplicateKeys = true;
            inherit indent;
          };

          findFirstPrefixOr =
            name: default: lib.findFirst (prefix: lib.hasPrefix prefix name) default importantPrefixes;
          no-prefix = "__NO_PREFIX";

          grouped = fields |> groupByAttrs' (n: _: (findFirstPrefixOr n no-prefix));

          prefixed = builtins.removeAttrs grouped [ no-prefix ];
          rest = grouped.${no-prefix} or { };

          grouped_rendered =
            importantPrefixes
            |> builtins.map (prefix: prefixed.${prefix} or null)
            |> builtins.filter (x: x != null)
            |> builtins.map renderFields'
            |> join;
        in
        join [
          grouped_rendered
          (renderFields' rest)
        ];

      wrapNamespace =
        indent: name: s:
        "${indent}${name} {\n${s |> lib.removePrefix "\n" |> lib.removeSuffix "\n"}\n${indent}}";

      # renders inside of sections using renderSection
      renderSections =
        indent: sections: sections |> lib.concatMapAttrsStringSep "\n" (renderSection indent);

      renderDag =
        indent: name: value:
        assert builtins.isAttrs value;
        let
          toPretty = lib.generators.toPretty { };
          toposorted = dag.topoSort value;
        in
        if value == { } then
          ""
        else
          assert lib.assertMsg (!(toposorted ? cycle))
            "Cycle detected in DAG!\ncycle:${toPretty toposorted.cycle}\nloops:${toPretty toposorted.loops}\n";
          toposorted.result
          # |> lib.traceValSeq
          |> builtins.map (x: render (incIndent indent) { ${x.name} = x.data; })
          |> join
          |> wrapNamespace indent name;

      # list needs to be special-cased since non-fields list can still mix fields and sections
      renderList =
        indent: name: list:
        assert builtins.isString indent;
        assert builtins.isString name;
        assert builtins.isList list;
        # assert lib.traceValFn (_: "################") true;
        # assert lib.traceValFn (_: lib.generators.toPretty {} list) true;
        let
          inherit (groupSectionsFieldsList list) fields sections;
          wrap =
            x:
            # assert lib.traceValFn (_: "WRAP:") true;
            # assert lib.traceValFn (_: lib.generators.toPretty {} x) true;
            { ${name} = x; };
        in
        if list == [ ] then
          ""
        else
          join (
            [ (renderFields indent (wrap fields)) ] ++ (sections |> builtins.map (renderSection indent name))
          );

      renderSection =
        indent: name: value:
        assert builtins.isString indent;
        assert builtins.isString name;
        assert isSection value;
        let
          type =
            # lib.traceValFn (type: "name: ${name} type: ${type} value: ${lib.generators.toPretty {multiline = false;} value}")
            dag.getType value;
        in
        if value == [ ] || value == { } then
          ""
        else if type == "set" then
          wrapNamespace indent name (render (incIndent indent) value)
        else if type == "list" then
          renderList indent name value
        else if
          type == "append"
        # map to rendering lists
        then
          renderList indent name value.contents
        else if type == "dag" then
          renderDag indent name value.content
        else if type == "dag-entry" then
          renderFields indent { ${name} = value.data; }
        # these last two are for docs purpose
        else if type == "bool" then
          lib.boolToString
        else
          builtins.toString value;

      render =
        indent: config:
        assert builtins.isAttrs config;
        let
          inherit (groupSectionsFieldsAttrs config) fields sections;
        in
        join [
          (renderFields indent fields)
          (renderSections indent sections)
        ];
    in
    render (indentOf indentLevel) config;

  toHyprconf =
    {
      indentLevel ? 0,
      importantPrefixes ? [ "$" ],
      generatorComments ? false,
    }@args:
    mod:
    mod
    |> evalConfig
    # |> lib.traceValFn (lib.generators.toPretty {})
    |> (
      config:
      configToHyprconf ((builtins.removeAttrs args [ "generatorComments" ]) // { inherit config; })
    );
in
{
  inherit
    evalConfig
    evalConfig'
    configToHyprconf
    toHyprconf
    ;
}
