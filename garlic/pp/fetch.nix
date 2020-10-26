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
# We only fetch the config, stdout and stderr by default
, fetchAll ? false
}:

with garlicTools;

let
  experimentName = baseNameOf (toString experimentStage);
  rsyncFilter = if (fetchAll) then "" else ''
    --include='*/*/garlic_config.json' \
    --include='*/*/std*.log' \
    --include='*/*/*/std*.log' \
    --exclude='*/*/*/*' '';
in
  stdenv.mkDerivation {
    name = "fetch";
    preferLocalBuild = true;

    buildInputs = [ rsync openssh curl nix ];
    phases = [ "installPhase" ];
    # This doesn't work when multiple users have different directories where the
    # results are stored.
    #src = /. + "${prefix}${experimentName}";

    installPhase = ''
      cat > $out << EOF
      #!/bin/sh -e
      mkdir -p ${garlicTemp}
      export PATH=$PATH
      rsync -av \
        --copy-links \
        ${rsyncFilter} \
        '${sshHost}:${prefix}/${experimentName}' ${garlicTemp}

      res=\$(nix-build -E '(with import ./default.nix; garlic.pp.getExpResult { \
        experimentStage = "${experimentStage}"; \
        trebuchetStage = "${trebuchetStage}"; \
        garlicTemp = "${garlicTemp}"; \
      })')

      rm -rf ${garlicTemp}/${experimentName}

      echo "The results for experiment ${experimentName} are at:"
      echo "  \$res"

      EOF
      chmod +x $out
    '';
  }
