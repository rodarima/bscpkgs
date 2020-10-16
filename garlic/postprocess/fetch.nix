{
  stdenv
, rsync
, openssh
, nix
, curl
, garlicTools
}:

{
  sshHost
, prefix
, experimentStage
, trebuchetStage
, garlicTemp
}:

with garlicTools;

let
  experimentName = baseNameOf (toString experimentStage);
in
  stdenv.mkDerivation {
    name = "fetch";
    preferLocalBuild = true;

    buildInputs = [ rsync openssh curl ];
    phases = [ "installPhase" ];

    installPhase = ''
      cat > $out << EOF
      #!/bin/sh -e
      mkdir -p ${garlicTemp}
      export PATH=${rsync}/bin:${openssh}/bin:${nix}/bin
      rsync -av \
        --copy-links \
        --include='*/*/*.log' --include='*/*/*.json' --exclude='*/*/*' \
        '${sshHost}:${prefix}/${experimentName}' ${garlicTemp}

      res=\$(nix-build -E '(with import ./default.nix; garlic.getExpResult { \
        experimentStage = "${experimentStage}"; \
        trebuchetStage = "${trebuchetStage}"; \
        garlicTemp = "${garlicTemp}"; \
      })')

      echo "The results for experiment ${experimentName} are at:"
      echo "  \$res"
      EOF
      chmod +x $out
    '';
  }
