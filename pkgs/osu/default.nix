{
  stdenv
, fetchurl
, mpi
, lib
, symlinkJoin
}:

let
  mpiAll = symlinkJoin {
    name = "mpi-all";
    paths = [ mpi.all ];
  };
in

stdenv.mkDerivation rec {
  version = "7.1-1";
  name = "osu-micro-benchmarks-${version}";

  src = fetchurl {
    url = "https://mvapich.cse.ohio-state.edu/download/mvapich/osu-micro-benchmarks-${version}.tar.gz";
    sha256 = "sha256-hfTdi+HfMSVeIyhSdprluC6HpfsUvi+Ouhrp3o/+ORo=";
  };

  doCheck = true;
  enableParallelBuilding = true;
  buildInputs = [ mpiAll ];
  hardeningDisable = [ "all" ];
  configureFlags = [ 
      "CC=mpicc"
      "CXX=mpicxx"
  ];

  postInstall = ''
    mkdir -p $out/bin
    for f in $(find $out -executable -type f); do
      ln -s "$f" $out/bin/$(basename "$f")
    done
  '';

  meta = {
    description = "OSU Micro-Benchmarks";
    homepage = http://mvapich.cse.ohio-state.edu/benchmarks/;
    maintainers = [ ];
    platforms = lib.platforms.all;
  };
}
