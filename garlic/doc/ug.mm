.COVER
.TL
Garlic: User guide
.AF "Barcelona Supercomputing Center"
.AU "Rodrigo Arias Mallo"
.COVEND
.H 1 "Overview"
Dependency graph of a complete experiment that produces a figure. Each box
is a derivation and arrows represent \fBbuild dependencies\fP.
.DS CB
.PS
linewid=0.9;
right
box "Source" "code"
arrow <-> "Develop" above
box "Program"
arrow <-> "Experiment" above
box "Results"
arrow <-> "Data" "exploration"
box "Figures"
.PE
.DE
.H 1 "Development"
.P
The development phase consists in creating a functional program by
modifying the source code. This process is generally cyclic, where the
developer needs to compile the program, correct mistakes and debug the
program.
.P
It requires to be running in the target machine.
.\" ===================================================================
.H 1 "Experimentation"
The experimentation phase begins with a functional program which is the
object of study. The experimenter then designs an experiment aimed at
measuring some properties of the program. The experiment is then
executed and the results are stored for further analysis.
.H 2 "Writing the experiment configuration"
.P
The term experiment is quite overloaded in this document. We are going
to see how to write the recipe that describes the execution pipeline of
an experiment.
.P
Within the garlic benchmark, experiments are typically sorted by a
hierarchy depending on which application they belong. Take a look at the
\fCgarlic/exp\fP directory and you will find some folders and .nix
files.
.P
Each of those recipes files describe a function that returns a
derivation, which, once built will result in the first stage script of
the execution pipeline.
.P
The first part of states the name of the attributes required as the
input of the function. Typically some packages, common tools and options:
.DS I
.VERBON
{
  stdenv
, stdexp
, bsc
, targetMachine
, stages
, garlicTools
}:
.VERBOFF
.DE
.P
Notice the \fCtargetMachine\fP argument, which provides information
about the machine in which the experiment will run. You should write
your experiment in such a way that runs in multiple clusters.
.DS I
.VERBON
varConf = {
  blocks = [ 1 2 4 ];
  nodes = [ 1 ];
};
.VERBOFF
.DE
.P
The \fCvarConf\fP is the attribute set that allows you to vary some
factors in the experiment.
.DS I
.VERBON
genConf = var: fix (self: targetMachine.config // {
  expName = "example";
  unitName = self.expName + "-b" + toString self.blocks;
  blocks = var.blocks;
  nodes = var.nodes;
  cpusPerTask = 1;
  tasksPerNode = self.hw.socketsPerNode;
});
.VERBOFF
.DE
.P
The \fCgenConf\fP function is the central part of the description of the
experiment. Takes as input \fBone\fP configuration from the cartesian
product of
.I varConfig
and returns the complete configuration. In our case, it will be
called 3 times, with the following inputs at each time:
.DS I
.VERBON
{ blocks = 1; nodes = 1; }
{ blocks = 2; nodes = 1; }
{ blocks = 4; nodes = 1; }
.VERBOFF
.DE
.P
The return value can be inspected by calling the function in the
interactive nix repl:
.DS I
.VERBON
nix-repl> genConf { blocks = 2; nodes = 1; }
{
  blocks = 2;
  cpusPerTask = 1;
  expName = "example";
  hw = { ... };
  march = "skylake-avx512";
  mtune = "skylake-avx512";
  name = "mn4";
  nixPrefix = "/gpfs/projects/bsc15/nix";
  nodes = 1;
  sshHost = "mn1";
  tasksPerNode = 2;
  unitName = "example-b2";
}
.VERBOFF
.DE
.P
Some configuration parameters were added by
.I targetMachine.config ,
such as the
.I nixPrefix ,
.I sshHost
or the
.I hw
attribute set, which are specific for the cluster they experiment is
going to run. Also, the
.I unitName
got assigned the proper name based on the number of blocks, but the
number of tasks per node were assigned based on the hardware description
of the target machine.
.P
By following this rule, the experiments can easily be ported to machines
with other hardware characteristics, and we only need to define the
hardware details once. Then all the experiments will be updated based on
those details.
.H 2 "First steps"
.P
The complete results generally take a long time to be finished, so it is
advisable to design the experiments iteratively, in order to quickly
obtain some feedback. Some recommendations:
.BL
.LI
Start with one unit only.
.LI
Set the number of runs low (say 5) but more than one.
.LI
Use a small problem size, so the execution time is low.
.LI
Set the time limit low, so deadlocks are caught early.
.LE
.P
As soon as the first runs are complete, examine the results and test
that everything looks good. You would likely want to check:
.BL
.LI
The resources where assigned as intended (nodes and CPU affinity).
.LI
No errors or warnings: look at stderr and stdout logs.
.LI
If a deadlock happens, it will run out of the time limit.
.LE
.P
As you gain confidence over that the execution went as planned, begin
increasing the problem size, the number of runs, the time limit and
lastly the number of units. The rationale is that each unit that is
shared among experiments gets assigned the same hash. Therefore, you can
iteratively add more units to an experiment, and if they are already
executed (and the results were generated) is reused.
.TC
