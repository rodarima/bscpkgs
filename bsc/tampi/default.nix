{
  stdenv
, fetchurl
, automake
, autoconf
, libtool
, gnumake
, boost
, mpi
, gcc}:

let
  inherit stdenv fetchurl;
  version = "1.0.1";
in
{
    hello = stdenv.mkDerivation rec {
    name = "tampi-${version}";
    enableParallelBuilding = true;
    buildInputs = [ automake autoconf libtool gnumake boost mpi gcc ];
    #hardeningDisable = [ "format" ];
    preConfigure = ''
        autoreconf -fiv
    '';
    configureFlags = [ "--disable-mpi-mt-check" ];
    src = fetchurl {
      url = "https://github.com/bsc-pm/tampi/archive/v${version}.tar.gz";
      sha256 = "8608a74325939d2a6b56e82f7f6788efbc67731e2d64793bac69475f5b4b9704";
    };
  };
}
