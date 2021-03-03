{
  stdenv,
  fetchurl,
  mpi
}:

stdenv.mkDerivation rec {
  version = "5.7";
  name = "osu-micro-benchmarks-${version}";

  src = fetchurl {
    url = "http://mvapich.cse.ohio-state.edu/download/mvapich/osu-micro-benchmarks-${version}.tar.gz";
    sha256 = "1425ygxpk3kyy6ilh4f6qjsjdyx0gjjzs7ic1cb7zjmn1vhfnw0l";
  };

  doCheck = true;
  enableParallelBuilding = true;
  buildInputs = [ mpi ];
  configureFlags = [ 
      "CC=${mpi}/bin/mpicc"
      "CXX=${mpi}/bin/mpicxx"
  ];

  postInstall = ''
    mkdir -p $out/bin
    cp $out/libexec/osu-micro-benchmarks/mpi/one-sided/* $out/bin/
    cp $out/libexec/osu-micro-benchmarks/mpi/collective/* $out/bin/
    cp $out/libexec/osu-micro-benchmarks/mpi/pt2pt/* $out/bin/
    cp $out/libexec/osu-micro-benchmarks/mpi/startup/* $out/bin/
  '';

  meta = {
    description = "OSU Micro-Benchmarks";
    homepage = http://mvapich.cse.ohio-state.edu/benchmarks/;
    maintainers = [ ];
    platforms = stdenv.lib.platforms.all;
  };
}
