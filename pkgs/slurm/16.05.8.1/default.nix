{ stdenv, lib, fetchFromGitHub, pkg-config, libtool, curl
, python3, munge, perl, pam, zlib, shadow, coreutils
, ncurses, libmysqlclient, lua, hwloc, numactl
, readline, freeipmi, xorg, lz4, rdma-core, nixosTests
, pmix, enableX11 ? false
}:

stdenv.mkDerivation rec {
  pname = "slurm";
  version = "16.05.8.1";

  # N.B. We use github release tags instead of https://www.schedmd.com/downloads.php
  # because the latter does not keep older releases.
  src = fetchFromGitHub {
    owner = "SchedMD";
    repo = "slurm";
    # The release tags use - instead of .
    rev = "${pname}-${builtins.replaceStrings ["."] ["-"] version}";
    sha256 = "1fkrbi4f22jb2pq19sv3j2yyvac4nh25fk8mzw6ic24swxp8wq9s";
  };

  outputs = [ "out" "dev" ];

  patches = [
    ./major.patch
    ./mvwprintw.patch
    # increase string length to allow for full
    # path of 'echo' in nix store
    #./common-env-echo.patch
    # Required for configure to pick up the right dlopen path
    #./pmix-configure.patch
  ];

  prePatch = ''
    substituteInPlace src/common/env.c \
        --replace "/bin/echo" "${coreutils}/bin/echo"
  '';

  # nixos test fails to start slurmd with 'undefined symbol: slurm_job_preempt_mode'
  # https://groups.google.com/forum/#!topic/slurm-devel/QHOajQ84_Es
  # this doesn't fix tests completely at least makes slurmd to launch
  hardeningDisable = [ "fortify" "bindnow" ];

  nativeBuildInputs = [ pkg-config libtool python3 ];
  buildInputs = [
    curl python3 munge perl pam zlib
      libmysqlclient ncurses lz4 rdma-core
      lua hwloc numactl readline freeipmi shadow.su
      pmix
  ];

  configureFlags = [
    "CFLAGS=-fcommon"
    "--with-freeipmi=${freeipmi}"
    "--with-hwloc=${hwloc}"
    "--with-lz4=${lz4.dev}"
    "--with-munge=${munge}"
    "--with-zlib=${zlib}"
    "--with-ofed=${rdma-core}"
    "--sysconfdir=/etc/slurm"
    "--with-pmix=${pmix}"
    "--disable-gtktest"
    "--disable-x11"
  ];


  preConfigure = ''
    patchShebangs ./doc/html/shtml2html.py
    patchShebangs ./doc/man/man2html.py
  '';

  postInstall = ''
    rm -f $out/lib/*.la $out/lib/slurm/*.la
  '';

  enableParallelBuilding = true;

  passthru.tests.slurm = nixosTests.slurm;

  meta = with lib; {
    homepage = "http://www.schedmd.com/";
    description = "Simple Linux Utility for Resource Management";
    platforms = platforms.linux;
    license = licenses.gpl2;
    maintainers = with maintainers; [ jagajaga markuskowa ];
  };
}
