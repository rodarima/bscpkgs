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
    };

    oss = callPackage ./hpcg/oss.nix {
      inherit genInput;
    };

    ossGranularity = callPackage ./hpcg/oss.granularity.192.nix {
      inherit genInput;
    };

    # ossScalability = callPackage ./hpcg/oss.scalability.192.nix {
    #   inherit genInput;
    # };

    ossSlicesWeakscaling = callPackage ./hpcg/oss.slices.weakscaling.nix {
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
    sigsegv = callPackage ./slurm/sigsegv.nix { };
    exit1 = callPackage ./slurm/exit1.nix { };
  };

  lulesh = {
    test = callPackage ./lulesh/test.nix { };
  };

  fwi = rec {
    granularity = callPackage ./fwi/granularity.nix { };
    ss = callPackage ./fwi/ss.nix { };
    reuse = callPackage ./fwi/reuse.nix { };
    io = callPackage ./fwi/io.nix { };

    # Extended experiments
    big.io = io.override { enableExtended = true; };
  };

  osu = rec {
    latency = callPackage ./osu/latency.nix { };
    latencyShm = latency.override { interNode = false; };
    latencyMt = latency.override { enableMultithread = true; };
    latencyMtShm = latency.override { enableMultithread = true; interNode = true; };
    bw = callPackage ./osu/bw.nix { };
    impi = callPackage ./osu/impi.nix { };
    bwShm = bw.override { interNode = false; };
    mtu = callPackage ./osu/mtu.nix { };
    eager = callPackage ./osu/eager.nix { };
  };

  examples = {
    granularity = callPackage ./examples/granularity.nix { };
  };
}
