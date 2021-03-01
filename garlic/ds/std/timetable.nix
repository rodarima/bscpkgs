{
  stdenv
, python3
}:

resultTree:

stdenv.mkDerivation {
  name = "timetable.json";
  preferLocalBuild = true;
  src = ./timetable.py;
  phases = [ "unpackPhase" "installPhase" ];

  unpackPhase = ''
    cp $src timetable.py
  '';

  buildInputs = [ python3 ];
  installPhase = ''
    touch $out
    python timetable.py ${resultTree} > $out
  '';
}
