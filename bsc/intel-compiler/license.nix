{ stdenv
, requireFile
}:

stdenv.mkDerivation rec {
  name = "intel-compiler-license";
  version = "2019.7.217";

  src = requireFile {
    name = "license.lic";
    sha256 = "1wi4a2f7hpc0v3gvbcdawvlj6yaqpkk20y1184d0zbx1cxrmwqxp";
    message = ''
      The Intel Compiler requires a license. You can get one (free of charge) if
      you meet the requeriments at the website:

        https://software.intel.com/content/www/us/en/develop/articles/qualify-for-free-software.html#opensourcecontributor

      Or you can use your own license. Add it to the store with:

        $ nix-store --add-fixed sha256 license.lic
        /nix/store/2p9v0nvsl3scshjx348z6j32rh7ac0db-license.lic

      Notice that the name must match exactly "license.lic".

      Then update the hash in the bsc/intel-compiler/license.nix file using the
      nix-hash command with:

        $ nix-hash --type sha256 --base32 --flat /nix/store/2p9v0nvsl3scshjx348z6j32rh7ac0db-license.lic
        06g2xgm1lch6zqfkhb768wacdx46kf61mfvj5wfpyssw0anr0x9q
    '';
  };

  dontUnpack = true;

  installPhase = ''
    mkdir -p $out
    cp $src $out/
  '';
}
