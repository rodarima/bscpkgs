{ jemalloc }:

jemalloc.overrideAttrs (old: {
  configureFlags = old.configureFlags ++ [
    "--with-jemalloc-prefix=nanos6_je_"
    "--enable-stats"
  ];
  hardeningDisable = [ "all" ];
})
