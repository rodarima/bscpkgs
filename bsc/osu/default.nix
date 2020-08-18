{
  stdenv,
  fetchurl,
  mpi
}:

stdenv.mkDerivation rec {
  version = "5.6.3";
  name = "osu-micro-benchmarks-${version}";

  src = fetchurl {
    url = "http://mvapich.cse.ohio-state.edu/download/mvapich/osu-micro-benchmarks-${version}.tar.gz";
    sha256 = "1f5fc252c0k4rd26xh1v5017wfbbsr2w7jm49x8yigc6n32sisn5";
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
