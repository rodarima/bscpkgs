{ pkgs ? import ./. }:

with pkgs;
with bsc;

mkShell {
  name = "garlic-shell";

  buildInputs =
    # Packages from garlic
    (with garlic; [ tool garlicd ]) ++
    # Packages from bsc
    [ groff paraver icc nix openssh git ];

  # inputsFrom to get build dependencies

  shellHook = ''
    alias l="ls -l --color=auto -v"
    alias ll="ls -l --color=auto -v"
    alias lh="ls -hAl --color=auto -v"
    alias ls="ls --color=auto -v"
    alias ..="cd .."

    export LANG=C

    echo Welcome to the garlic shell
  '';
}
