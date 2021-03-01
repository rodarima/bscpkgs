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
}
