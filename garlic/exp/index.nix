{
  super
, self
, bsc
, garlic
, callPackage
}:

{
  nbody = rec {
    granularity = callPackage ./nbody/granularity.nix { };
    ss = callPackage ./nbody/ss.nix { };
    numa = callPackage ./nbody/numa.nix { };
  };

  saiph = {
    granularity = callPackage ./saiph/granularity.nix { };
    ss = callPackage ./saiph/ss.nix { };
  };

  creams = rec {
    ss = callPackage ./creams/ss.nix { };
    granularity = callPackage ./creams/granularity.nix { };
    size = callPackage ./creams/size.nix { };
    granularity16 = callPackage ./creams/granularity16.nix { };

    # These experiments are the extended versions of the previous
    # ones. We split them so we can keep a reasonable execution time
    big.granularity = granularity.override { enableExtended = true; };
    big.ss = granularity.override { enableExtended = true; };
  };

  hpcg = rec {
    granularity = callPackage ./hpcg/granularity.nix { };
    ss = callPackage ./hpcg/scaling.nix { };
    ws = ss.override { enableStrong=false; };
    size = callPackage ./hpcg/size.nix { };

    big.ss = ss.override { enableExtended = true; };
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
