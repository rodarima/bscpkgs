.TL
Garlic: experiment results
.AU
Rodrigo Arias Mallo
.AI
Barcelona Supercomputing Center
.\"#####################################################################
.nr GROWPS 3
.nr PSINCR 1.5p
.\".nr PD 0.5m
.nr PI 2m
\".2C
.\"#####################################################################
.LP
Consider a program of interest for which an experiment has been designed to
measure some properties. When the experiment is executed, it will generate some
results which are generally non-deterministic. The experimenter may want to
present some information in a visual plot or graph based on these results.
.PP
In this escenario, the experiment depends on the program\[em]any
changes in the program will cause nix to build the experiment again using the
updated program. The results will also depend on the experiment, and
the graph on the results. This chain of dependencies can be shown in
the following dependency tree:
.PS
right
circlerad=0.22; arrowhead=7;
circle "Prog"
arrow
circle "Exp"
arrow
circle "Result"
arrow
circle "Graph"
.PE
Ideally, the dependencies should be handled by nix, so it can detect any
change and rebuild the necessary parts automatically. Unfortunately, nix
is not able to build R as a derivation directly as it requires access
to the
.I "target cluster"
with several user accounts. In addition, the results are often
non-deterministic so the graph G cannot depend on the content of the
results.
.PP
In order to let several users use the results from a cache, we use the
.I "nix store"
to make them available for read only. To generate the results from the
experiment, we add some extra steps that must be executed manually.
.PS
right
circlerad=0.22; arrowhead=7;
circle "Prog"
arrow
E: circle "Exp"
RUN: circle "Run" at E + (0.8,-0.5)
FETCH: circle "Fetch" at E + (1.6,-0.5)
R: circle "Result" at E + (2.4,0)
arrow
G: circle "Graph"
arrow dashed from E to RUN chop
arrow dashed from RUN to FETCH chop
arrow dashed from FETCH to R chop
arrow from E to R chop
.PE
The run and fetch steps are provided by the helper tool
.I garlic ,
which launches the experiment using the user credential at the
.I "target cluster"
and then fetches the results, placing them in a directory known by nix.
Is the directory is not found, nix will issue a message to suggest the
user to launch the experiment and it will fail to build the result
derivation. When the result is successfully built by any user, the
derivation won't need to be rebuilt again until the experiment changes,
as the hash only depends on the experiment and not on the contents of
the results.
