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
    # TODO: Add the specific details for SLURM and the interconection here
  };
}
