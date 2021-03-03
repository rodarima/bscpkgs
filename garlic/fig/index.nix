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
  };

  hpcg = with exp.hpcg; {
    oss = stdPlot ./hpcg/oss.R [ oss ];
  };

  saiph = with exp.saiph; {
    granularity = stdPlot ./saiph/granularity.R [ granularity ];
  };

  heat = with exp.heat; {
    test = stdPlot ./heat/test.R [ test ];
  };

  creams = with exp.creams; {
    ss = stdPlot ./creams/ss.R [ ss.hybrid ss.pure ];
  };

  osu = with exp.osu; {
    latency       = customPlot ./osu/latency.R (ds.osu.latency latency.result);
    latencyShm    = customPlot ./osu/latency.R (ds.osu.latency latencyShm.result);
    latencyMt     = customPlot ./osu/latency.R (ds.osu.latency latencyMt.result);
    latencyMtShm  = customPlot ./osu/latency.R (ds.osu.latency latencyMtShm.result);

    bw    = customPlot ./osu/bw.R (ds.osu.bw bw.result);
    bwShm = customPlot ./osu/bw.R (ds.osu.bw bwShm.result);
  };

  # The figures used in the article contained in a directory per figure
  article = with fig; linkTree "article-fig" {
    "osu/latency"     = osu.latency;
    "osu/latencyMt"   = osu.latencyMt;
    "osu/bw"          = osu.bw;
    "osu/bwShm"       = osu.bwShm;
  };
}
