{
  super
, self
, bsc
, garlic
, callPackage
}:

{
  nbody = rec {
    baseline = callPackage ./nbody/nblocks.nix { };

    # Experiment variants
    small = baseline.override {
      particles = 12 * 4096;
    };
    # TODO: Update freeCpu using a non-standard pipeline
    #freeCpu = baseline.override { freeCpu = true; };
    jemalloc = baseline.override { enableJemalloc = true; };

    # Some experiments with traces
    trace = {
      # Only one unit repeated 30 times
      baseline = small.override {
        enableCTF = true;
        loops = 30;
        steps = 1;
      };

      # Same but with jemalloc enabled
      jemalloc = trace.baseline.override {
        enableJemalloc = true;
      };
    };
  };

  saiph = {
    numcomm = callPackage ./saiph/numcomm.nix { };
    granularity = callPackage ./saiph/granularity.nix { };
  };

  creams = {
    ss = {
      pure = callPackage ./creams/ss+pure.nix { };
      hybrid = callPackage ./creams/ss+hybrid.nix { };
    };
  };

  hpcg = rec {
    #serial = callPackage ./hpcg/serial.nix { };
    #mpi = callPackage ./hpcg/mpi.nix { };
    #omp = callPackage ./hpcg/omp.nix { };
    #mpi_omp = callPackage ./hpcg/mpi+omp.nix { };
    #input = callPackage ./hpcg/gen.nix {
    #  inherit (bsc.garlic.pp) resultFromTrebuchet;
    #};
    genInput = callPackage ./hpcg/gen.nix {
      inherit (bsc.garlic.pp) resultFromTrebuchet;
    };

    oss = callPackage ./hpcg/oss.nix {
      inherit genInput;
    };
  };

  heat = {
    test = callPackage ./heat/test.nix { };
  };

  bigsort = rec {
    genseq = callPackage ./bigsort/genseq.nix {
      n = toString (1024 * 1024 * 1024 / 8); # 1 GB input size
      dram = toString (1024 * 1024 * 1024); # 1 GB chunk
    };

    shuffle = callPackage ./bigsort/shuffle.nix {
      inputTre = genseq;
      n = toString (1024 * 1024 * 1024 / 8); # 1 GB input size
      dram = toString (1024 * 1024 * 1024); # 1 GB chunk
      inherit (bsc.garlic.pp) resultFromTrebuchet;
    };

    sort = callPackage ./bigsort/sort.nix {
      inputTre = shuffle;
      inherit (bsc.garlic.pp) resultFromTrebuchet;
      removeOutput = false;
    };
  };

  slurm = {
    cpu = callPackage ./slurm/cpu.nix { };
  };
}