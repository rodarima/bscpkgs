{
  super
, self
, bsc
, garlic
, callPackage
}:

let
  rPlot = garlic.pp.rPlot;
  exp = garlic.exp;
  pp = garlic.pp;
  ds = garlic.ds;
  fig = garlic.fig;

  stdPlot = rScript: expList: rPlot {
    script = rScript;
    dataset = pp.mergeDatasets (map (e: ds.std.timetable e.result) expList);
  };

  customPlot = rScript: dataset: rPlot {
    script = rScript;
    dataset = dataset;
  };

  linkTree = name: tree: self.linkFarm name (
    self.lib.mapAttrsToList (
      name: value: { name=name; path=value; }
    ) tree);
in
{
  nbody = with exp.nbody; {
    baseline  = stdPlot ./nbody/baseline.R [ baseline ];
    small     = stdPlot ./nbody/baseline.R [ small ];
    jemalloc  = stdPlot ./nbody/jemalloc.R [ baseline jemalloc ];
    ctf       = stdPlot ./nbody/baseline.R [ ctf ];
    scaling   = stdPlot ./nbody/baseline.R [ scaling ];
  };

  hpcg = with exp.hpcg; {
    oss = stdPlot ./hpcg/oss.R [ oss ];
  };

  saiph = with exp.saiph; {
    granularity = stdPlot ./saiph/granularity.R [ granularity ];
    ss = stdPlot ./saiph/ss.R [ ss ];
  };

  heat = with exp.heat; {
    granularity = stdPlot ./heat/granularity.R [ granularity ];
    cache = customPlot ./heat/cache.R (ds.perf.stat cache.result);
    ctf = customPlot ./heat/mode.R (ds.ctf.mode ctf.result);
  };

  creams = with exp.creams; {
    ss = stdPlot ./creams/ss.R [ ss ];
    granularity = stdPlot ./creams/granularity.R [ granularity ];

    # Extended version (we could use another R script for those plots
    big.ss = stdPlot ./creams/ss.R [ big.ss ];
    big.granularity = stdPlot ./creams/granularity.R [ big.granularity ];
  };

  fwi = with exp.fwi; {
    test              = stdPlot ./fwi/test.R [ test ];
    strong_scaling    = stdPlot ./fwi/strong_scaling.R [ strong_scaling_task strong_scaling_forkjoin strong_scaling_mpionly ];
    strong_scaling_io = stdPlot ./fwi/strong_scaling_io.R [ strong_scaling_io ];
    granularity       = stdPlot ./fwi/granularity.R [ granularity ];
  };

  osu = with exp.osu; {
    latency       = customPlot ./osu/latency.R (ds.osu.latency latency.result);
    latencyShm    = customPlot ./osu/latency.R (ds.osu.latency latencyShm.result);
    latencyMt     = customPlot ./osu/latency.R (ds.osu.latency latencyMt.result);
    latencyMtShm  = customPlot ./osu/latency.R (ds.osu.latency latencyMtShm.result);

    bw    = customPlot ./osu/bw.R (ds.osu.bw bw.result);
    bwShm = customPlot ./osu/bw.R (ds.osu.bw bwShm.result);
    impi  = customPlot ./osu/impi.R (ds.osu.bw impi.result);
  };

  # The figures used in the article contained in a directory per figure
  article = with fig; linkTree "article-fig" {
    "osu/latency"     = osu.latency;
    "osu/latencyMt"   = osu.latencyMt;
    "osu/bw"          = osu.bw;
    "osu/bwShm"       = osu.bwShm;
    "heat/cache"      = heat.cache;
  };

  examples = with exp.examples; {
    granularity = stdPlot ./examples/granularity.R [ granularity ];
  };
}
