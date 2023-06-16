{
  stdenv
, fetchurl
, mpi
, lib
}:

stdenv.mkDerivation rec {
  version = "7.1-1";
  name = "osu-micro-benchmarks-${version}";

  src = fetchurl {
    url = "https://mvapich.cse.ohio-state.edu/download/mvapich/osu-micro-benchmarks-${version}.tar.gz";
    sha256 = "sha256-hfTdi+HfMSVeIyhSdprluC6HpfsUvi+Ouhrp3o/+ORo=";
  };

  doCheck = true;
  enableParallelBuilding = true;
  buildInputs = [ mpi ];
  hardeningDisable = [ "all" ];
  configureFlags = [ 
      "CC=${mpi}/bin/mpicc"
      "CXX=${mpi}/bin/mpicxx"
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
