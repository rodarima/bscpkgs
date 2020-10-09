{
  stdenv
}:

{
  # MareNostrum 4 configuration
  mn4 = {
    config = {
      name = "mn4";
      sshHosts = [ "mn1" "mn2" "mn3" ];
      nixPrefix = "/gpfs/projects/bsc15/nix";
      cachelineBytes = 64;
      march = "skylake-avx512";
      mtune = "skylake-avx512";
    };
    # TODO: Add the specific details for SLURM and the interconection here
  };
}
