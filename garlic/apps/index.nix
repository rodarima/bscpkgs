{
  super
, self
, bsc
, garlic
, callPackage
}:

{
  nbody = callPackage ./nbody/default.nix { };

  saiph = callPackage ./saiph/default.nix {
    cc = bsc.clangOmpss2;
    L3SizeKB = garlic.targetMachine.config.hw.cacheSizeKB.L3;
    cachelineBytes = garlic.targetMachine.config.hw.cachelineBytes;
  };

  creams = callPackage ./creams/default.nix {
    gnuDef   = self.gfortran10 ; # Default GNU   compiler version
    intelDef = bsc.icc    ; # Default Intel compiler version
  };

  creamsInput = callPackage ./creams/input.nix { };

  hpcg = callPackage ./hpcg/default.nix { };

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

  fwi = rec {
    params = callPackage ./fwi/params.nix { };
    solver = callPackage ./fwi/default.nix {
      fwiParams = params;
    };
  };
}
