{ stdenv, lib, fetchFromGitHub, pkg-config, libtool, curl
, python3, munge, perl, pam, openssl
, ncurses, libmysqlclient, gtk2, lua, hwloc, numactl
, readline, freeipmi, libssh2, xorg
, pmix
# enable internal X11 support via libssh2
, enableX11 ? true
}:

stdenv.mkDerivation rec {
  name = "slurm-libpmi2-${version}";
  version = "17.11.9-2";

  # N.B. We use github release tags instead of https://www.schedmd.com/downloads.php
  # because the latter does not keep older releases.
  src = fetchFromGitHub {
    owner = "SchedMD";
    repo = "slurm";
    # The release tags use - instead of .
    rev = "${builtins.replaceStrings ["."] ["-"] name}";
    sha256 = "1lq4ac6yjai6wh979dciw8v3d99zbd3w36rfh0vpncqm672fg1qy";
  };

  outputs = [ "out" ];

  prePatch = lib.optional enableX11 ''
    substituteInPlace src/common/x11_util.c \
        --replace '"/usr/bin/xauth"' '"${xorg.xauth}/bin/xauth"'
  '';

  # nixos test fails to start slurmd with 'undefined symbol: slurm_job_preempt_mode'
  # https://groups.google.com/forum/#!topic/slurm-devel/QHOajQ84_Es
  # this doesn't fix tests completely at least makes slurmd to launch
  hardeningDisable = [ "bindnow" ];

  nativeBuildInputs = [ pkg-config libtool ];
  buildInputs = [
    curl python3 munge perl pam openssl
      libmysqlclient ncurses gtk2
      lua hwloc numactl readline freeipmi
      pmix
  ] ++ lib.optionals enableX11 [ libssh2 xorg.xauth ];

  configureFlags = with lib;
    [ "--with-munge=${munge}"
      "--with-ssl=${openssl.dev}"
      "--with-hwloc=${hwloc.dev}"
      "--with-freeipmi=${freeipmi}"
      "--sysconfdir=/etc/slurm"
      "--with-pmix=${pmix}"
    ] ++ (optional (gtk2 == null)  "--disable-gtktest")
      ++ (optional enableX11 "--with-libssh2=${libssh2.dev}");


  preConfigure = ''
    patchShebangs ./doc/html/shtml2html.py
    patchShebangs ./doc/man/man2html.py
    patchShebangs ./configure
  '';

  preBuild = ''cd contribs/pmi2'';

  #buildPhase = ''
  #  pushd contrib/pmi2
  #    make -j install SHELL=${SHELL}
  #  popd
  #'';

  postInstall = ''
    rm -f $out/lib/*.la $out/lib/slurm/*.la
  '';

  enableParallelBuilding = true;

  meta = with lib; {
    homepage = http://www.schedmd.com/;
    description = "Simple Linux Utility for Resource Management";
    platforms = platforms.linux;
    license = licenses.gpl2;
    maintainers = with maintainers; [ jagajaga markuskowa ];
  };
}
