{
  stdenv
}:

{
    hello = stdenv.mkDerivation rec {
      name = "dummy";

      src = null;
      dontUnpack = true;

      buildPhase = ''
        ls -l /
        echo "${stdenv}"
      '';
    };
}
