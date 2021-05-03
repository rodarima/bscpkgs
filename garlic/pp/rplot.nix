{
  stdenv
, rWrapper
, rPackages
, fontconfig
, dejavu_fonts
, liberation_ttf
, noto-fonts
, makeFontsConf
, makeFontsCache
, jq
, fetchFromGitHub
, writeText
, runCommand
, glibcLocales
}:

{
# The two results to be compared
  dataset
, script
, extraRPackages ? []
}:

with stdenv.lib;

let
  scalesPatched = with rPackages; buildRPackage {
    name = "scales";
    src = fetchFromGitHub {
      owner = "mikmart";
      repo = "scales";
      #ref = "label-bytes";
      rev = "fa7d91c765b6b5d2f682c7c22e0478d96c2ea76c";
      sha256 = "10dsyxp9pxzdmg04xpnrxqhc4qfhbkr3jhx8whfr7z27wgfrr1n3";
    };
    propagatedBuildInputs = [ farver labeling lifecycle munsell R6 RColorBrewer viridisLite ];
    nativeBuildInputs = [ farver labeling lifecycle munsell R6 RColorBrewer viridisLite ];
  };

  customR = rWrapper.override {
    packages = with rPackages; [ scalesPatched tidyverse viridis egg
      Cairo extrafont ] ++ extraRPackages;
  };

  myFonts = [
    dejavu_fonts
    #noto-fonts
    #liberation_ttf
  ];

  cacheConf =
  let
    cache = makeFontsCache { fontDirectories = myFonts; };
  in
  writeText "fc-00-nixos-cache.conf" ''
    <?xml version='1.0'?>
    <!DOCTYPE fontconfig SYSTEM "fonts.dtd">
    <fontconfig>
      <!-- Font directories -->
      ${concatStringsSep "\n" (map (font: "<dir>${font}</dir>") myFonts)}
      ${optionalString (stdenv.hostPlatform == stdenv.buildPlatform) ''
      <!-- Pre-generated font caches -->
      <cachedir>${cache}</cachedir>
      ''}
    </fontconfig>
  '';

  # default fonts configuration file
  # priority 52
  defaultFontsConf =
    let genDefault = fonts: name:
      optionalString (fonts != []) ''
        <alias binding="same">
          <family>${name}</family>
          <prefer>
          ${concatStringsSep ""
          (map (font: ''
            <family>${font}</family>
          '') fonts)}
          </prefer>
        </alias>
      '';
    in
    writeText "fc-52-nixos-default-fonts.conf" ''
    <?xml version='1.0'?>
    <!DOCTYPE fontconfig SYSTEM "fonts.dtd">
    <fontconfig>
      <!-- Default fonts -->
      ${genDefault [ "DejaVu Sans" ]      "sans-serif"}
      ${genDefault [ "DejaVu Serif" ]     "serif"}
      ${genDefault [ "DejaVu Sans Mono" ] "monospace"}
      ${genDefault [ "Noto Color Emoji"]  "emoji"}
    </fontconfig>
  '';

  fontConfPath =
  let
    fixedConf = runCommand "fonts-fixed.conf" {
      preferLocalBuild = true;
    } ''
      head --lines=-2 ${fontconfig.out}/etc/fonts/fonts.conf >> $out

      cat >> $out << 'EOF'
      <!--
       Load local customization files, but don't complain
       if there aren't any
      -->
      <include ignore_missing="yes">conf.d</include>
      EOF

      tail -2 ${fontconfig.out}/etc/fonts/fonts.conf >> $out
    '';
  in
  runCommand "fontconfig-conf" {
    preferLocalBuild = true;
  } ''
    dst=$out/etc/fonts/conf.d
    mkdir -p $dst
    # fonts.conf
    ln -s ${fixedConf} $dst/../fonts.conf

    # fontconfig default config files
    ln -s ${fontconfig.out}/etc/fonts/conf.d/*.conf \
          $dst/

    # 00-nixos-cache.conf
    ln -s ${cacheConf}  $dst/00-nixos-cache.conf

    # 52-nixos-default-fonts.conf
    ln -s ${defaultFontsConf} $dst/52-nixos-default-fonts.conf
  '';

in stdenv.mkDerivation {
  name = "plot";
  buildInputs = [ customR jq fontconfig glibcLocales ];
  preferLocalBuild = true;
  dontPatchShebangs = true;
  phases = [ "installPhase" ];

  installPhase = ''
    export FONTCONFIG_PATH=${fontConfPath}/etc/fonts/
    export LANG=en_US.UTF-8

    mkdir -p $out
    cd $out
    dataset=$(readlink -f ${dataset}/dataset)

    ln -s $dataset input
    Rscript --vanilla ${script} "$dataset" "$out"

    # HACK: replace the \minus for a \hyphen to keep the file paths intact, so
    # they can be copied to the terminal directly. The StandardEncoding is not
    # working (AdobeStd.enc).
    find "$out" -name '*.pdf' | xargs -l1 sed -i 's.45/minus.45/hyphen.g'

    if [ "''${dataset##*.}" == gz ]; then
      gunzip --stdout $dataset
    else
      cat $dataset
    fi | jq -c .total_time |\
      awk '{s+=$1} END {printf "%f\n", s/60}' > total_job_time_minutes
  '';
}
