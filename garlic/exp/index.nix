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

    # Some experiments with traces
    trace = {
      # Only one unit repeated 30 times
      baseline = small.override {
        enableCTF = true;
        loops = 30;
        steps = 1;
      };

    };

    scaling = callPackage ./nbody/scaling.nix {
      particles = 12 * 4096;
    };
  };

  saiph = {
    granularity = callPackage ./saiph/granularity.nix { };
    ss = callPackage ./saiph/ss.nix { };
  };

  creams = rec {
    ss = callPackage ./creams/ss.nix { };
    granularity = callPackage ./creams/granularity.nix { };

    # These experiments are the extended versions of the previous
    # ones. We split them so we can keep a reasonable execution time
    big.granularity = granularity.override { enableExtended = true; };
    big.ss = granularity.override { enableExtended = true; };
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

  heat = rec {
    granularity = callPackage ./heat/granularity.nix { };
    cache = granularity.override { enablePerf = true; };
    ctf = granularity.override { enableCTF = true; };
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

  lulesh = {
    test = callPackage ./lulesh/test.nix { };
  };

  fwi = {
    granularity             = callPackage ./fwi/granularity.nix { };
    strong_scaling_task     = callPackage ./fwi/strong_scaling_task.nix { };
    strong_scaling_forkjoin = callPackage ./fwi/strong_scaling_forkjoin.nix { };
    strong_scaling_mpionly  = callPackage ./fwi/strong_scaling_mpionly.nix { };
    data_reuse              = callPackage ./fwi/data_reuse.nix { };
    strong_scaling_io       = callPackage ./fwi/strong_scaling_io.nix { };
    sync_io                 = callPackage ./fwi/sync_io.nix { };
  };

  osu = rec {
    latency = callPackage ./osu/latency.nix { };
    latencyShm = latency.override { interNode = false; };
    latencyMt = latency.override { enableMultithread = true; };
    latencyMtShm = latency.override { enableMultithread = true; interNode = true; };
    bw = callPackage ./osu/bw.nix { };
    impi = callPackage ./osu/impi.nix { };
    bwShm = bw.override { interNode = false; };
  };

  examples = {
    granularity = callPackage ./examples/granularity.nix { };
  };
}
