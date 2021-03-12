{
  stdenv
, python3
, gzip
}:

resultTree:

stdenv.mkDerivation {
  name = "ctf-mode.json.gz";
  preferLocalBuild = true;
  src = ./mode.py;
  phases = [ "unpackPhase" "installPhase" ];

  unpackPhase = ''
    cp $src mode.py
  '';

  buildInputs = [ python3 gzip ];
  installPhase = ''
    python mode.py ${resultTree} | gzip > $out
  '';
}
