{
  super
, self
, bsc
, garlic
, callPackage
}:

with garlic.pp;

let
  exp = garlic.exp;
in
{
  nbody = with exp.nbody; {
    baseline = merge [ baseline ];
    small = merge [ small ];
    jemalloc = merge [ baseline jemalloc ];
    #freeCpu  = merge [ baseline freeCpu ];
    ctf = merge [ ctf ];
  };

  hpcg = with exp.hpcg; {
    oss = merge [ oss ];
  };

  saiph = with exp.saiph; {
    numcomm = merge [ numcomm ];
    granularity = merge [ granularity ];
  };

  heat = with exp.heat; {
    test = merge [ test ];
  };

  creams = with exp.creams.ss; {
    ss.hybrid = merge [ hybrid ];
    ss.pure = merge [ pure ];
    ss.all = merge [ hybrid pure ];
  };
}
