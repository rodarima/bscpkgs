{
  stdenv
}:

{
  # MareNostrum 4 configuration
  mn4 = {
    config = {
      name = "mn4";
      sshHost = "mn1";
      nixPrefix = "/gpfs/projects/bsc15/nix";
      march = "skylake-avx512";
      mtune = "skylake-avx512";
      hw = {
        cpusPerNode = 48;
        cpusPerSocket = 24;
        socketsPerNode = 2;
        cachelineBytes = 64;
      };
    };

    # Experimental naming convention for the FS
    fs = rec {
      topology = {
        gpfs = {
          projects = "/gpfs/projects/bsc15/garlic";
          scratch = "/gpfs/scratch/bsc15/bsc15557/garlic";
        };

        ssd = {
          # Beware to expand the temp dir at execution time
          temp = "$TMPDIR";
        };
      };

      shared = with topology; {
        fast = gpfs.scratch;
        reliable = gpfs.projects;
      };

      local = {
        temp = topology.ssd.temp;
      };
    };

    # TODO: Add the specific details for SLURM and the interconection here
  };
}
