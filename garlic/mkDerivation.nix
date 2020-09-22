{ lib }:

let inherit (lib) optional; in

mkDerivation:

args:

let
  args_ = {

    enableParallelBuilding = args.enableParallelBuilding or true;

    hardeningDisable = [ "all" ];

  };
in

mkDerivation (args // args_)
