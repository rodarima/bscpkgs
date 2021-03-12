{
  super
, self
, bsc
, garlic
, callPackage
}:

{
  std = {
    timetable = callPackage ./std/timetable.nix {};
  };

  osu = {
    latency = callPackage ./osu/latency.nix {};
    bw = callPackage ./osu/bw.nix {};
  };

  perf.stat = callPackage ./perf/stat.nix {};

  ctf.mode = callPackage ./ctf/mode.nix {};
}
