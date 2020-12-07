{
  super
, self
, bsc
, garlic
, callPackage
}:

{
  nbody = callPackage ./nbody/default.nix {
    gitBranch = "garlic/seq";
  };

  saiph = callPackage ./saiph/default.nix {
    cc = bsc.clangOmpss2;
  };

  creams = callPackage ./creams/default.nix {
    gnuDef   = self.gfortran10 ; # Default GNU   compiler version
    intelDef = bsc.icc    ; # Default Intel compiler version
    gitBranch = "garlic/mpi+send+seq";
  };

  creamsInput = callPackage ./creams/input.nix {
    gitBranch = "garlic/mpi+send+seq";
  };

  hpcg = callPackage ./hpcg/default.nix {
    gitBranch = "garlic/oss";
  };

  bigsort = {
    sort = callPackage ./bigsort/default.nix {
      gitBranch = "garlic/mpi+send+omp+task";
    };

    genseq = callPackage ./bigsort/genseq.nix { };

    shuffle = callPackage ./bigsort/shuffle.nix { };
  };

  heat = callPackage ./heat/default.nix { };

  miniamr = callPackage ./miniamr/default.nix {
    variant = "ompss-2";
  };

  ifsker = callPackage ./ifsker/default.nix { };

  lulesh = callPackage ./lulesh/default.nix { };

  hpccg = callPackage ./hpccg/default.nix { };

  fwi = callPackage ./fwi/default.nix { };
}
