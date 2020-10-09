{
  stdenv
}:

with stdenv.lib;

let
  gen = rec {
    # genAttrSets "a" ["hello" "world"]
    # [ { a = "hello"; } { a = "world"; } ]
    genAttrSets = (name: arr: (map (x: {${name}=x; })) arr);

    # addAttrSets "a" [1 2] {e=4;}
    # [ { a = 1; e = 4; } { a = 2; e = 4; } ]
    addAttrSets = (name: arr: set: (map (x: set // {${name}=x; })) arr);

    # attrToList {a=1;}
    # [ { name = "a"; value = 1; } ]
    attrToList = (set: map (name: {name=name; value=set.${name};} ) (builtins.attrNames set));

    # mergeConfig [{e=1;}] {name="a"; value=[1 2]
    # [ { a = 1; e = 1; } { a = 2; e = 1; } ]
    mergeConfig = (arr: new: flatten ( map (x: addAttrSets new.name new.value x) arr));

    # genConfigs {a=[1 2]; b=[3 4];}
    # [ { a = 1; b = 3; } { a = 1; b = 4; } { a = 2; b = 3; } { a = 2; b = 4; } ]
    genConfigs = (config: foldl mergeConfig [{}] (attrToList config));

    # Generate multiple app versions by override with each config
    genApp = (app: configs: map (conf: app.override conf // {conf=conf;}) configs);

    # Generate app version from an array of apps
    genApps = (apps: configs:
      flatten (map (app: genApp app configs) apps));

    /* Returns the path of the executable of a stage */
    stageProgram = stage:
      if stage ? programPath
      then "${stage}${stage.programPath}"
      else "${stage}";

  };
in
  gen
