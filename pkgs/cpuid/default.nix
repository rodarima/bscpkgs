{
  stdenv
, perl # For the pod2man command
}:

stdenv.mkDerivation rec {
  version = "20201006";
  pname = "cpuid";

  buildInputs = [ perl ];

  # Replace /usr install directory for $out
  postPatch = ''
    sed -i "s@/usr@$out@g" Makefile
  '';

  src = builtins.fetchTarball {
    url = "http://www.etallen.com/cpuid/${pname}-${version}.src.tar.gz";
    sha256 = "04qhs938gs1kjxpsrnfy6lbsircsprfyh4db62s5cf83a1nrwn9w";
  };
}
