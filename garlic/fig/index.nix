{
  super
, self
, bsc
, garlic
, callPackage
}:

let
  rPlot = garlic.pp.rPlot;
  ds = garlic.ds;
in
{
  nbody = {
    baseline = rPlot {
      script = ./nbody/baseline.R;
      dataset = ds.nbody.baseline;
    };
    small = rPlot {
      script = ./nbody/baseline.R;
      dataset = ds.nbody.small;
    };
    jemalloc = rPlot {
      script = ./nbody/jemalloc.R;
      dataset = ds.nbody.jemalloc;
    };
    #freeCpu = rPlot {
    #  script = ./nbody/freeCpu.R;
    #  dataset = ds.nbody.freeCpu;
    #};
    ctf = rPlot {
      script = ./nbody/baseline.R;
      dataset = ds.nbody.ctf;
    };
  };

  hpcg = {
    oss = with ds.hpcg; rPlot {
      script = ./hpcg/oss.R;
      dataset = oss;
    };
  };

  saiph = {
    granularity = with ds.saiph; rPlot {
      script = ./saiph/granularity.R;
      dataset = granularity;
    };
  };

  heat = {
    test = with ds.heat; rPlot {
      script = ./heat/test.R;
      dataset = test;
    };
  };
}
