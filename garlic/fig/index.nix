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
    granularity = stdPlot ./nbody/granularity.R [ granularity ];
    nodesorsockets = stdPlot ./nbody/nodes-or-sockets.R [ nodesorsockets ];
    scaling = stdPlot ./nbody/scaling.R [ scaling ];
  };

  hpcg = with exp.hpcg; {
    ss = stdPlot ./hpcg/ss.R [ ss ];
    ws = stdPlot ./hpcg/ws.R [ ws ];
    size = stdPlot ./hpcg/size.R [ size ];
    granularity = stdPlot ./hpcg/granularity.R [ granularity ];
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
    granularity = stdPlot ./fwi/granularity.R [ granularity ];
    reuse       = stdPlot ./fwi/granularity.R [ reuse ];
    ss = stdPlot ./fwi/ss.R [ ss ];
    io = stdPlot ./fwi/io.R [ io ];
  };

  osu = with exp.osu; {
    latency       = customPlot ./osu/latency.R (ds.osu.latency latency.result);
    latencyShm    = customPlot ./osu/latency.R (ds.osu.latency latencyShm.result);
    latencyMt     = customPlot ./osu/latency.R (ds.osu.latency latencyMt.result);
    latencyMtShm  = customPlot ./osu/latency.R (ds.osu.latency latencyMtShm.result);

    bw    = customPlot ./osu/bw.R (ds.osu.bw bw.result);
    bwShm = customPlot ./osu/bw.R (ds.osu.bw bwShm.result);
    impi  = customPlot ./osu/impi.R (ds.osu.bw impi.result);
    mtu   = customPlot ./osu/mtu.R (ds.osu.bw mtu.result);
    eager   = customPlot ./osu/eager.R (ds.osu.bw eager.result);
  };

  # The figures used in the article contained in a directory per figure
  article = with fig; linkTree "article-fig" {
    "osu/latency"     = osu.latency;
    "osu/bw"          = osu.bw;
    "osu/mtu"         = osu.mtu;
  };

  examples = with exp.examples; {
    granularity = stdPlot ./examples/granularity.R [ granularity ];
  };
}
