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

  exptt = exlist: map (e: e.timetable) exlist;
  rPlotExp = rScript: exp: rPlot {
    script = rScript;
    dataset = pp.mergeDatasets (exptt exp);
  };
in
{
  nbody = with exp.nbody; {
    baseline  = rPlotExp ./nbody/baseline.R [ baseline ];
    small     = rPlotExp ./nbody/baseline.R [ small ];
    jemalloc  = rPlotExp ./nbody/jemalloc.R [ baseline jemalloc ];
    ctf       = rPlotExp ./nbody/baseline.R [ ctf ];
  };

  hpcg = with exp.hpcg; {
    oss = rPlotExp ./hpcg/oss.R [ oss ];
  };

  saiph = with exp.saiph; {
    granularity = rPlotExp ./saiph/granularity.R [ granularity ];
  };

  heat = with exp.heat; {
    test = rPlotExp ./heat/test.R [ test ];
  };

  creams = with exp.creams; {
    ss = rPlotExp ./creams/ss.R [ ss.hybrid ss.pure ];
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
