.TL
Garlic: the execution pipeline
.AU
Rodrigo Arias Mallo
.AI
Barcelona Supercomputing Center
.AB
.LP
This document covers the execution of experiments in the Garlic
benchmark, which are performed under strict conditions. The several
stages of the execution are documented so the experimenter can have a
global overview of how the benchmark runs under the hood.
The measurements taken during the execution of the experiment are stored
in a file used in posterior processing steps.
.AE
.\"#####################################################################
.nr GROWPS 3
.nr PSINCR 1.5p
.\".nr PD 0.5m
.nr PI 2m
\".2C
.\"#####################################################################
.NH 1
Introduction
.LP
Every experiment in the Garlic
benchmark is controlled by a single
.I nix
file placed in the
.CW garlic/exp
subdirectory.
Experiments are formed by several
.I "experimental units"
or simply
.I units .
A unit is the result of each unique configuration of the experiment 
(typically involves the cartesian product of all factors) and
consists of several shell scripts executed sequentially to setup the
.I "execution environment" ,
which finally launch the actual program being analyzed.
The scripts that prepare the environment and the program itself are
called the
.I stages
of the execution and altogether form the
.I "execution pipeline"
or simply the
.I pipeline .
The experimenter must know with very good details all the stages
involved in the pipeline, as they have a large impact on the execution.
.PP
Additionally, the execution time is impacted by the target machine in
which the experiments run. The software used for the benchmark is
carefully configured and tuned for the hardware used in the execution;
in particular, the experiments are designed to run in MareNostrum 4
cluster with the SLURM workload manager and the Omni-Path
interconnection network. In the future we plan to add
support for other clusters in order to execute the experiments in other
machines.
.\"#####################################################################
.NH 1
Isolation
.LP
The benchmark is designed so that both the compilation of every software
package and the execution of the experiment is performed under strict
conditions. We can ensure that two executions of the same experiment are
actually running the same program in the same software environment.
.PP
All the software used by an experiment is included in the
.I "nix store"
which is, by convention, located at the
.CW /nix
directory. Unfortunately, it is common for libraries to try to load
software from other paths like
.CW /usr
or
.CW /lib .
It is also common that configuration files are loaded from
.CW /etc
and from the home directory of the user that runs the experiment.
Additionally, some environment variables are recognized by the libraries
used in the experiment, which change their behavior. As we cannot
control the software and configuration files in those directories, we
couldn't guarantee that the execution behaves as intended.
.PP
In order to avoid this problem, we create a
.I sandbox
where only the files in the nix store are available (with some other
exceptions). Therefore, even if the libraries try to access any path
outside the nix store, they will find that the files are not there
anymore. Additionally, the environment variables are cleared before
entering the environment (with some exceptions as well).
.\"#####################################################################
.NH 1
Execution pipeline
.LP
Several predefined stages form the
.I standard
execution pipeline and are defined in the
.I stdPipeline
array. The standard pipeline prepares the resources and the environment
to run a program (usually in parallel) in the compute nodes. It is
divided in two main parts:
connecting to the target machine to submit a job and executing the job.
Finally, the complete execution pipeline ends by running the actual
program, which is not part of the standard pipeline, as should be
defined differently for each program.
.NH 2
Job submission
.LP
Some stages are involved in the job submission: the
.I trebuchet
stage connects via
.I ssh
to the target machine and executes the next stage there. Once in the
target machine, the
.I isolate
stage is executed to enter the sandbox and the
.I experiment
stage is executed, running the experiment which launches several
.I unit
stages.
.PP
Each unit executes a
.I sbatch
stage which runs the
.I sbatch(1)
program with a job script that simply executes the next stage. The
sbatch program internally reads the
.CW /etc/slurm/slurm.conf
file from outside the sandbox, so we must explicitly allow this file to
be available, as well as the
.I munge
socket used for authentication by the SLURM daemon. Once the jobs are
submitted to SLURM, the experiment stage ends and the trebuchet finishes
the execution. The jobs will be queued for execution without any other
intervention from the user.
.PP
The rationale behind running sbatch from the sandbox is because the
options provided in environment variables override the options from the
job script. Therefore, we avoid this problem by running sbatch from the
sandbox, where the interfering environment variables are removed. The
sbatch program is also provided in the
.I "nix store" ,
with a version compatible with the SLURM daemon running in the target
cluster.
.NH 2
Job execution
.LP
Once an unit job has been selected for execution, SLURM
allocates the resources (usually several nodes) and then selects one of
the nodes to run the job script: it is not executed in parallel yet.
The job script runs from a child process forked from on of the SLURM
daemon processes, which are outside the sandbox. Therefore, we first run the
.I isolate
stage
to enter the sandbox again.
.PP
The next stage is called
.I control
and determines if enough data has been generated by the experiment unit
or if it should continue repeating the execution. At the current time,
it is only implemented as a simple loop that runs the next stage a fixed
amount of times (by default, it is repeated 30 times).
.PP
The following stage is
.I srun
which launches several copies of the next stage to run in
parallel (when using more than one task). Runs one copy per task,
effectively creating one process per task. The CPUs affinity is
configured by the parameter
.I --cpu-bind
and is important to set it correctly (see more details in the
.I srun(1)
manual). Appending the
.I verbose
value to the cpu bind option causes srun to print the assigned affinity
of each task, which is very valuable when examining the execution log.
.PP
The mechanism by which srun executes multiple processes is the same used
by sbatch, it forks from a SLURM daemon running in the computing nodes.
Therefore, the execution begins outside the sandbox. The next stage is
.I isolate
which enters again the sandbox in every task. All remaining stages are
running now in parallel.
.\" ###################################################################
.NH 2
The program
.LP
At this point in the execution, the standard pipeline has been
completely executed, and we are ready to run the actual program that is
the matter of the experiment. Usually, programs require some arguments
to be passed in the command line. The
.I exec
stage sets the arguments (and optionally some environment variables) and
executes the last stage, the
.I program .
.PP
The experimenters are required to define these last stages, as they
define the specific way in which the program must be executed.
Additional stages may be included before or after the program run, so
they can perform additional steps.
.\" ###################################################################
.NH 2
Stage overview
.LP
The complete execution pipeline using the standard pipeline is shown in
the Table 1. Some properties are also reflected about the execution
stages.
.KF
.TS
center;
lB cB cB cB cB cB
l  c  c  c  c  c.
_
Stage     	Target	Safe	Copies	User	Std
_
trebuchet	xeon	no	no	yes	yes
isolate 	login	no	no	yes	yes
experiment	login	yes	no	no	yes
unit    	login	yes	no	no	yes
sbatch  	login	yes	no	no	yes
_
isolate 	comp	no	no	no	yes
control 	comp	yes	no	no	yes
srun    	comp	yes	no	no	yes
isolate    	comp	no	yes	no	yes
_
exec    	comp	yes	yes	no	no
program    	comp	yes	yes	no	no
_
.TE
.QS
.B "Table 1" :
The stages of a complete execution pipeline. The
.B target
column determines where the stage is running,
.B safe
states if the stage begins the execution inside the sandbox,
.B user
if it can be executed directly by the user,
.B copies
if there are several instances running in parallel and
.B std
if is part of the standard execution pipeline.
.QE
.KE
