{
  stdenv
, fetchFromGitHub
, cmake
}:

stdenv.mkDerivation rec {
  pname = "bigotes";
  version = "9dce13";
  src = fetchFromGitHub {
    owner = "rodarima";
    repo = "bigotes";
    rev = "9dce13446a8da30bea552d569d260d54e0188518";
    sha256 = "sha256-ktxM3pXiL8YXSK+/IKWYadijhYXqGoLY6adLk36iigE=";
  };
  buildInputs = [ cmake ];
}
