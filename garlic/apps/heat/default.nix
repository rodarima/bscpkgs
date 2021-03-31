{
  stdenv
, mpi
, tampi
, mcxx
, gitBranch ? "garlic/mpi+send+seq"
, gitCommit ? null
, garlicTools
}:

let
  gitTable = {
    # Auto-generated with garlic-git-table on 2021-03-31
    "garlic/mpi+send+oss+task"    = "947c80070d4c53e441df54b8bfac8928b10c5fb2";
    "garlic/mpi+send+seq"         = "f41e1433808d0cbecd88a869b451c927747e5d42";
    "garlic/tampi+isend+oss+task" = "b1273f9b4db32ba6e15e3d41343e67407ce2f54f";
    "garlic/tampi+send+oss+task"  = "554bec249f9aa23dd92edcfa2ada1e03e05e121d";
  };

  # Find the actual commit
  _gitCommit = garlicTools.findCommit {
    inherit gitCommit gitTable gitBranch;
  };
  _gitBranch = gitBranch;

in

  stdenv.mkDerivation rec {

    name = "heat";

    src = builtins.fetchGit {
      url = "ssh://git@bscpm03.bsc.es/garlic/apps/heat.git";
      ref = _gitBranch;
      rev = _gitCommit;
    };

    gitBranch = _gitBranch;
    gitCommit = _gitCommit;

    patches = [ ./print-times.patch ];

    buildInputs = [ mpi mcxx tampi ];

    programPath = "/bin/${name}";

    installPhase = ''
      mkdir -p $out/bin
      cp ${name} $out/bin/

      mkdir -p $out/etc
      cp heat.conf $out/etc/
    '';

  }
