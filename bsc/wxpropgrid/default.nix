{
  stdenv
, fetchurl
, wxGTK28
}:

let
  #wx = wxGTK31; # BUG
  wx = wxGTK28;
in
stdenv.mkDerivation rec {
  pname = "wxpropgrid";
  version = "1.4.15";

  src = fetchurl {
    url = "http://prdownloads.sourceforge.net/wxpropgrid/wxpropgrid-${version}-src.tar.gz";
    sha256 = "1f62468x5s4h775bn5svlkv0lzzh06aciljpiqn5k3w2arkaijgh";
  };

  enableParallelBuilding = false;

  buildInputs = [
    wx
  ];

}
