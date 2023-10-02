#!/bin/bash

# This post build hook sends the closure of the just built derivation to the
# target machine. In our case this is the MareNostrum4 cluster.

# set -e fails as the profile runs some erroring programs
# We need the profile to load nix in the $PATH
. /etc/profile

set -eu
set -f # disable globbing
export IFS=' '
nixroot=/gpfs/projects/bsc15/nix
store=$nixroot/nix/store
target=ssh://mn

nix copy --to $target $OUT_PATHS
