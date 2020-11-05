{
  stdenv
, mpi
, tampi
, clangOmpss2
, bsx ? 1024
, bsy ? 1024
}:

stdenv.mkDerivation rec {
  name = "heat";
  extension = if (bsx == bsy)
    then "${toString bsx}bs.exe"
    else "${toString bsx}x${toString bsy}bs.exe";

  variant = "heat_ompss";
  target = "${variant}.${extension}";

  makeFlags = [
    "BSX=${toString bsx}"
    "BSY=${toString bsy}"
    target
  ];

  src = ~/heat;
  #src = builtins.fetchGit {
  #  url = "ssh://git@bscpm02.bsc.es/garlic/apps/heat.git";
  #  ref = "garlic";
  #};

  buildInputs = [
    mpi
    clangOmpss2
    tampi
  ];

  programPath = "/bin/${target}";

  installPhase = ''
    mkdir -p $out/bin
    cp ${target} $out/bin/

    mkdir -p $out/etc
    cp heat.conf $out/etc/
  '';

}
