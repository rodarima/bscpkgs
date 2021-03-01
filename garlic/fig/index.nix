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

  stdPlot = rScript: expList: rPlot {
    script = rScript;
    dataset = pp.mergeDatasets (map (e: ds.std.timetable e.result) expList);
  };
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
    #latency = pp.osu-latency latency.result;
    latency =
    let
      resultJson = pp.osu-latency latency.result;
    in
      rPlot {
        script = ./osu/latency.R;
        dataset = resultJson;
      };
  };
}
