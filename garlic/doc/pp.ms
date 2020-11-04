.TL
Garlic: the post-processing pipeline
.AU
Rodrigo Arias Mallo
.AI
Barcelona Supercomputing Center
.AB
.LP
In this document the stages posterior to the execution of the experiment
are explained. We consider the post-processing pipeline the steps to go
from the generated data from the experiment to a set of plots or tables
that present the data in a human readable form.
.AE
.\"#####################################################################
.nr GROWPS 3
.nr PSINCR 1.5p
.\".nr PD 0.5m
.nr PI 2m
.\".2C
.R1
bracket-label " [" ] ", "
accumulate
.R2
.\"#####################################################################
.NH 1
Introduction
.LP
After the correct execution of an experiment some measurements are
recorded in the results for further investigation. Typically the time of
the execution is measured and presented later in a plot or a table. The
steps to analyze the results and present them in a convenient way is
called the
.I "post-processing pipeline" .
Similarly to the execution pipeline
.[
garlic execution
.]
where several stages run sequentially, the
post-processing pipeline is also formed by multiple stages executed in
order.
.PP
The rationale behind dividing execution and post-processing is
that usually the experiments are costly to run (they take a long time to
complete) while generating a plot is usually shorter. Refining the plots
multiple times reusing the same experimental results doesn't require the
execution of the complete experiment, so the experimenter can try
multiple ways to present the data in a rapid cycle.
.NH 1
Fetching the results
.LP
Consider a program of interest for which an experiment has been designed to
measure some properties that the experimenter wants to present in a
visual plot. When the experiment is launched, the execution
pipeline (EP) is completely executed and it will generate some
results. In this escenario, the execution pipeline depends on the
program\[em]any changes in the program will cause nix to build it again
using the updated program. The results will also depend on the
execution pipeline, and the graph on the results. This chain of
dependencies can be shown in the following dependency graph:
.\"circlerad=0.22; arrowhead=7;
.PS
right
circle "Prog"
arrow
circle "EP"
arrow
circle "Result"
arrow
circle "PP"
arrow
circle "Plot"
.PE
Ideally, the dependencies should be handled by nix, so it can detect any
change and rebuild the necessary parts automatically. Unfortunately, nix
is not able to build the result as a derivation directly as it requires access
to the
.I "target cluster"
with several user accounts. In order to let several users reuse the same results from a cache, we
use the
.I "nix store"
to make them available. To generate the results from the
experiment, we add some extra steps that must be executed manually.
.PS
right
circlerad=0.22; arrowhead=7;
circle "Prog"
arrow
E: circle "EP"
RUN: circle "Run" at E + (0.8,-0.5) dashed
FETCH: circle "Fetch" at E + (1.6,-0.5) dashed
R: circle "Result" at E + (2.4,0)
arrow
P: circle "PP"
arrow
circle "Plot"
arrow dashed from E to RUN chop
arrow dashed from RUN to FETCH chop
arrow dashed from FETCH to R chop
arrow from E to R chop
.PE
The run and fetch steps are provided by the helper tool
.I "garlic(1)" ,
which launches the experiment using the user credentials at the
.I "target cluster"
and then fetches the results, placing them in a directory known by nix.
When the result derivation needs to be built, nix will look in this
directory for the results of the execution. If the directory is not
found, a message is printed to suggest the user to launch the
experiment and the build process is stopped. When the
result is successfully built by any user, is stored in the
.I "nix store"
and it won't need to be rebuilt again until the experiment changes, as
the hash only depends on the experiment and not on the contents of the
results.
.PP
Notice that this mechanism violates the deterministic nature of the nix
store, as from a given input (the experiment) we can generate different
outputs (each result from different executions). We knowingly relaxed
this restriction by providing a guarantee that the results are
equivalent and there is no need to execute an experiment more than once.
.PP
To force the execution of an experiment you can use the
.I rev
attribute which is a number assigned to each experiment
and can be incremented to create copies that only differs on that
number. The experiment hash will change but the experiment will be the
same, as long as the revision number is ignored along the execution
stages.
