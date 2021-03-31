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

    /* Given a trebuchet, returns the experiment */
    getExperimentStage = drv:
      if (drv ? isExperiment) && drv.isExperiment then drv
      else getExperimentStage drv.nextStage;

    # Computes the exponentiation operation
    pow = x: n: fold (a: b: a*b) 1 (map (a: x) (range 1 n));

    # Generates a list of exponents from a to b inclusive, and raises base to
    # each element of the list.
    expRange = base: a: b: (map (ex: pow base ex) (range a b));

    # Generates a range from start to end (inclusive) by multiplying start by 2.
    range2 = start: end:
    let
      _range2 = s: e: if (s > e) then [] else [ s ] ++ (_range2 (s * 2) e);
    in
      _range2 start end;

    # Generates a list of integers by halving number N until it reaches 1. Is
    # sorted from the smallest to largest.
    halfList = N:
    let
      _divList = n: if (n == 0) then [] else (_divList (n / 2)) ++ [ n ];
    in
      _divList N;

    # A list of all divisors of n, sorted in increased order:
    divisors = n: filter (x: (mod n x == 0)) (range 1 n);

    # Generates a set given a list of keys, where all values are null.
    genNullAttr = l: genAttrs l (name: null);

    # From the keys in the lis l, generates a set with the values in the set a,
    # if they don't exist, they are not taken. Values set to null are removed.
    optionalInherit = l: a: filterAttrs (n: v: v!=null)
      (overrideExisting (genNullAttr l) a);

    # Given a float f, truncates it and returns the resulting the integer
    floatTruncate = f: let
      strFloat = toString f;
      slices = splitString "." strFloat;
      front = elemAt slices 0;
    in
      toInt front;

    # Returns the given gitCommit if not null, or the one stored in the
    # gitTable for the branch gitBranch.
    findCommit = {gitCommit ? null, gitTable, gitBranch}:
      if (gitCommit != null) then gitCommit else gitTable."${gitBranch}";

  };
in
  gen
