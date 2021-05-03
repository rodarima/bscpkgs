{
  super
, self
, bsc
, garlic
, callPackage
}:

rec {

  py = callPackage ./py.nix {};

  std.timetable = py { script = ./std-timetable.py; compress = false; };
  osu.latency = py { script = ./osu-latency.py; };
  osu.bw = py { script = ./osu-bw.py; };
  perf.stat = py { script = ./perf-stat.py; };
  ctf.mode = py { script = ./ctf-mode.py; };
}
