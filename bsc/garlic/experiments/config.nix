let
  lib = import <nixpkgs/lib>;

  inputParams = {
    # MPI implementation
    mpi = [
      "impi"
      "mpich"
    ];

    # Gcc compiler
    gcc = [
      "gcc9"
      "gcc7"
    ];

    # Additional cflags
    cflags = [
      ["-O3" "-fnobugs"]
      ["-Ofast"]
    ];

    # Which git branches
#    branches = [
#      "mpi+seq"
#      "seq"
#    ];
  };

  apps = [
    "dummy"
  ];

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
  mergeConfig = (arr: new: lib.flatten ( map (x: addAttrSets new.name new.value x) arr));

  # genConfigs {a=[1 2]; b=[3 4];}
  # [ { a = 1; b = 3; } { a = 1; b = 4; } { a = 2; b = 3; } { a = 2; b = 4; } ]
  genConfigs = (config: lib.foldl mergeConfig [{}] (attrToList config));


  # Generates all configs from inputParams
  allConfigs = (genConfigs inputParams);

in 
  {
    inherit allConfigs;
  }
