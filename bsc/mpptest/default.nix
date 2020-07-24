{
  stdenv
, mpi
, fetchurl
}:

stdenv.mkDerivation {
  name = "mpptest";

  src = fetchurl {
    url = "ftp://ftp.mcs.anl.gov/pub/mpi/tools/perftest.tar.gz";
    sha256 = "11i22lq3pch3pvmhnbsgxzd8ap4yvpvlhy2f7k8x3krdwjhl0jvl";
  };

  buildInputs = [ mpi ];
}
