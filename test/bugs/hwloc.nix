{
  stdenv
, hwloc
, strace
}:

stdenv.mkDerivation {
  name = "hwloc-test";

  src = ./.;

  buildInputs = [ hwloc strace ];

  buildPhase = ''
    ls -l /sys
    gcc -lhwloc hwloc.c -o hwloc
    strace ./hwloc
  '';

}
