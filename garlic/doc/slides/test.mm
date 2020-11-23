.\"usage: NS title
.de NS \" New Slide
.SK
.ev gp-top
.fam H
.vs 1.5m
.ll \\n[@ll]u
.lt \\n[@ll]u
.rs
.sp 2v
.ps +5
\\$*
.ps -5
.sp 1.5v
.br
.ev
..
.\" Remove headers
.de TP
..
.\" Bigger page number in footer
.de EOP
.fam H
.ps +2
.	ie o .tl \\*[pg*odd-footer]
.	el .tl \\*[pg*even-footer]
.	ds hd*format \\g[P]
.	af P 0
.	ie (\\n[P]=1)&(\\n[N]=1) .tl \\*[pg*header]
.	el .tl \\*[pg*footer]
.	af P \\*[hd*format]
.	tl ''\\*[Pg_type!\\n[@copy_type]]''
..
.\" Remove top and bottom margin
.VM 0 0
.\"
.\"
.\" Set virtual page dimensions for a physical size of 16x12 cm
.PGFORM 14c 12c 1c 1
.ND "November 24, 2020"
.\" .vs 1.5m
.S C 1.5m
.fam H
.\".PH "'cosas'''"
.COVER ms
.de cov@print-date
.DS C
.fam H
.B
\\*[cov*new-date]
.DE
..
.TL
.ps 20
.fam H
Garlic update
.AF "Barcelona Supercomputing Center"
.AU "Rodrigo Arias Mallo"
.COVEND
.PF "'''%'"
.\" Turn off justification
.SA 0
.\".PF '''%'
.\"==================================================================
.NS "Changelog"
Important changes since the last meeting (2020-09-23)
.BL
.LI
Execution of experiments is now \fBisolated\fP: no $HOME or /usr at run time
.LI
Added a \fBpostprocess\fP pipeline
.LI
New \fBgarlic(1)\fP helper tool (manual included)
.LI
A plot has an experiment result as \fBdependency\fP
.LI
Experiments run on demand based on article \fBfigures\fP
.LI
Fast pkg overrides (MPI)
.LE 1
.\"==================================================================
.NS "Execution pipeline (review)"
.2C
List of stages required to run the program of the experiment:
.BL
.S -1
.LI
The
.B target
column determines where the stage is running.
.LI
.B Safe
states if the stage begins the execution inside the isolated namespace
.LI
.B User
if it can be executed directly by the user
.LI
.B Copies
if there are several instances running in parallel and
.LI
.B Std
if is part of the standard execution pipeline.
.LE
.S P P
.\" Go to the next column
.NCOL
.KF
.defcolor white rgb #FFFFFF
.S 8 14p
.\".S C +0.2v
.TS
center expand;
lB lB cB cB cB cB cB
lB lB cB cB cB cB cB
r  lw(5.5m)  c  c  c  c  c.
	_	_	_	_	_	_
	Stage     	Target	Safe	Copies	User	Std
	_	_	_	_	_	_
\m[white]\(rh\m[]\
	trebuchet	xeon	no	no	yes	yes
	runexp  	login	no	no	yes	yes
	isolate 	login	no	no	no	yes
	experiment	login	yes	no	no	yes
	unit    	login	yes	no	no	yes
	sbatch  	login	yes	no	no	yes
	_	_	_	_	_	_
	isolate 	comp	no	no	no	yes
	control 	comp	yes	no	no	yes
	srun    	comp	yes	no	no	yes
	isolate    	comp	no	yes	no	yes
	_	_	_	_	_	_
	exec    	comp	yes	yes	no	no
	program    	comp	yes	yes	no	no
	_	_	_	_	_	_
.TE
.S P P
.KE
.1C
.\"==================================================================
.NS "Execution stages"
.2C
\fBtrebuchet\fP: connects via ssh to the target machine and executes the
next stage there.
.P
The target machine is set to MN4, which by default uses the host
\fBmn1\fP
.P
Literally:
.P
.VERBON
ssh mn1 /path/to/next/stage 
.VERBOFF
.P
You need to define the ssh config to be able to connect to mn1.
.\" Go to the next column
.NCOL
.KF
.S 8 14p
.\".S C +0.2v
.TS
center expand;
lB lB cB cB cB cB cB
lB lB cB cB cB cB cB
r  lw(5.5m)  c  c  c  c  c.
	_	_	_	_	_	_
	Stage     	Target	Safe	Copies	User	Std
	_	_	_	_	_	_
\(rh	\fBtrebuchet\fP	xeon	no	no	yes	yes
	runexp  	login	no	no	yes	yes
	isolate 	login	no	no	no	yes
	experiment	login	yes	no	no	yes
	unit    	login	yes	no	no	yes
	sbatch  	login	yes	no	no	yes
	_	_	_	_	_	_
	isolate 	comp	no	no	no	yes
	control 	comp	yes	no	no	yes
	srun    	comp	yes	no	no	yes
	isolate    	comp	no	yes	no	yes
	_	_	_	_	_	_
	exec    	comp	yes	yes	no	no
	program    	comp	yes	yes	no	no
	_	_	_	_	_	_
.TE
.S P P
.KE
.1C
.\"==================================================================
.NS "Execution stages"
.2C
\fBrunexp\fP: sets a few \fCGARLIC_*\fP environment variables used by the
benchmark and changes the current directory to the \fBout\fP directory.
.P
At build time, next stages don't know these values (cyclic dependency),
so they are populated at execution time.
.\" Go to the next column
.NCOL
.KF
.S 8 14p
.\".S C +0.2v
.TS
center expand;
lB lB cB cB cB cB cB
lB lB cB cB cB cB cB
r  lw(5.5m)  c  c  c  c  c.
	_	_	_	_	_	_
	Stage     	Target	Safe	Copies	User	Std
	_	_	_	_	_	_
	trebuchet	xeon	no	no	yes	yes
\(rh	\fBrunexp\fP  	login	no	no	yes	yes
	isolate 	login	no	no	no	yes
	experiment	login	yes	no	no	yes
	unit    	login	yes	no	no	yes
	sbatch  	login	yes	no	no	yes
	_	_	_	_	_	_
	isolate 	comp	no	no	no	yes
	control 	comp	yes	no	no	yes
	srun    	comp	yes	no	no	yes
	isolate    	comp	no	yes	no	yes
	_	_	_	_	_	_
	exec    	comp	yes	yes	no	no
	program    	comp	yes	yes	no	no
	_	_	_	_	_	_
.TE
.S P P
.KE
.1C
.\"==================================================================
.NS "Execution stages"
.2C
\fBisolate\fP: once on the target machine, we enter an isolated
namespace to load the nix store.
.P
Notice that this and the previous stages require the \fBsh\fP shell to be
available on the target machine
.P
They are not \fBsafe\fP as we run target machine code
.\" Go to the next column
.NCOL
.KF
.S 8 14p
.\".S C +0.2v
.TS
center expand;
lB lB cB cB cB cB cB
lB lB cB cB cB cB cB
r  lw(5.5m)  c  c  c  c  c.
	_	_	_	_	_	_
	Stage     	Target	Safe	Copies	User	Std
	_	_	_	_	_	_
	trebuchet	xeon	no	no	yes	yes
	runexp  	login	no	no	yes	yes
\(rh	\fBisolate\fP 	login	no	no	no	yes
	experiment	login	yes	no	no	yes
	unit    	login	yes	no	no	yes
	sbatch  	login	yes	no	no	yes
	_	_	_	_	_	_
	isolate 	comp	no	no	no	yes
	control 	comp	yes	no	no	yes
	srun    	comp	yes	no	no	yes
	isolate    	comp	no	yes	no	yes
	_	_	_	_	_	_
	exec    	comp	yes	yes	no	no
	program    	comp	yes	yes	no	no
	_	_	_	_	_	_
.TE
.S P P
.KE
.1C
.\"==================================================================
.NS "Execution stages"
.2C
\fBexperiment\fP: runs several units sequentially.
.P
Defines the \fCGARLIC_EXPERIMENT\fP environment variable.
.P
Creates a directory for the experiment and changes the current directory
there.
.\" Go to the next column
.NCOL
.KF
.S 8 14p
.\".S C +0.2v
.TS
center expand;
lB lB cB cB cB cB cB
lB lB cB cB cB cB cB
r  lw(5.5m)  c  c  c  c  c.
	_	_	_	_	_	_
	Stage     	Target	Safe	Copies	User	Std
	_	_	_	_	_	_
	trebuchet	xeon	no	no	yes	yes
	runexp  	login	no	no	yes	yes
	isolate 	login	no	no	no	yes
\(rh	\fBexperiment\fP	login	yes	no	no	yes
	unit    	login	yes	no	no	yes
	sbatch  	login	yes	no	no	yes
	_	_	_	_	_	_
	isolate 	comp	no	no	no	yes
	control 	comp	yes	no	no	yes
	srun    	comp	yes	no	no	yes
	isolate    	comp	no	yes	no	yes
	_	_	_	_	_	_
	exec    	comp	yes	yes	no	no
	program    	comp	yes	yes	no	no
	_	_	_	_	_	_
.TE
.S P P
.KE
.1C
.\"==================================================================
.NS "Execution stages"
.2C
\fBunit\fP: creates an index entry for the unit and the experiment.
.P
Creates a directory for the unit and changes the current directory
there.
.P
Copies the unit configuration in the \fCgarlic_config.json\fP file
.\" Go to the next column
.NCOL
.KF
.S 8 14p
.\".S C +0.2v
.TS
center expand;
lB lB cB cB cB cB cB
lB lB cB cB cB cB cB
r  lw(5.5m)  c  c  c  c  c.
	_	_	_	_	_	_
	Stage     	Target	Safe	Copies	User	Std
	_	_	_	_	_	_
	trebuchet	xeon	no	no	yes	yes
	runexp  	login	no	no	yes	yes
	isolate 	login	no	no	no	yes
	experiment	login	yes	no	no	yes
\(rh	\fBunit\fP    	login	yes	no	no	yes
	sbatch  	login	yes	no	no	yes
	_	_	_	_	_	_
	isolate 	comp	no	no	no	yes
	control 	comp	yes	no	no	yes
	srun    	comp	yes	no	no	yes
	isolate    	comp	no	yes	no	yes
	_	_	_	_	_	_
	exec    	comp	yes	yes	no	no
	program    	comp	yes	yes	no	no
	_	_	_	_	_	_
.TE
.S P P
.KE
.1C
.\"==================================================================
.NS "Execution stages"
.2C
\fBsbatch\fP: allocates resources and executes the next stage in the
first node.
.P
The execve call is performed by a SLURM daemon, so is \fBout\fP of the
isolated environment.
.\" Go to the next column
.NCOL
.KF
.S 8 14p
.\".S C +0.2v
.TS
center expand;
lB lB cB cB cB cB cB
lB lB cB cB cB cB cB
r  lw(5.5m)  c  c  c  c  c.
	_	_	_	_	_	_
	Stage     	Target	Safe	Copies	User	Std
	_	_	_	_	_	_
	trebuchet	xeon	no	no	yes	yes
	runexp  	login	no	no	yes	yes
	isolate 	login	no	no	no	yes
	experiment	login	yes	no	no	yes
	unit    	login	yes	no	no	yes
\(rh	\fBsbatch\fP  	login	yes	no	no	yes
	_	_	_	_	_	_
	isolate 	comp	no	no	no	yes
	control 	comp	yes	no	no	yes
	srun    	comp	yes	no	no	yes
	isolate    	comp	no	yes	no	yes
	_	_	_	_	_	_
	exec    	comp	yes	yes	no	no
	program    	comp	yes	yes	no	no
	_	_	_	_	_	_
.TE
.S P P
.KE
.1C
.\"==================================================================
.NS "Execution stages"
.2C
\fBisolate\fP: enters the isolated namespace again, with the nix store.
.P
Notice that we are now running in the compute node allocated by SLURM.
.\" Go to the next column
.NCOL
.KF
.S 8 14p
.\".S C +0.2v
.TS
center expand;
lB lB cB cB cB cB cB
lB lB cB cB cB cB cB
r  lw(5.5m)  c  c  c  c  c.
	_	_	_	_	_	_
	Stage     	Target	Safe	Copies	User	Std
	_	_	_	_	_	_
	trebuchet	xeon	no	no	yes	yes
	runexp  	login	no	no	yes	yes
	isolate 	login	no	no	no	yes
	experiment	login	yes	no	no	yes
	unit    	login	yes	no	no	yes
	sbatch  	login	yes	no	no	yes
	_	_	_	_	_	_
\(rh	\fBisolate\fP 	comp	no	no	no	yes
	control 	comp	yes	no	no	yes
	srun    	comp	yes	no	no	yes
	isolate    	comp	no	yes	no	yes
	_	_	_	_	_	_
	exec    	comp	yes	yes	no	no
	program    	comp	yes	yes	no	no
	_	_	_	_	_	_
.TE
.S P P
.KE
.1C
.\"==================================================================
.NS "Execution stages"
.2C
\fBcontrol\fP: runs the next stage several times
.P
Is controlled by the \fCloops\fP attribute, which specifies the number
of runs.
.P
Creates a directory with the number of the run and enters it.
.P
Generated results are placed in this directory.
.\" Go to the next column
.NCOL
.KF
.S 8 14p
.\".S C +0.2v
.TS
center expand;
lB lB cB cB cB cB cB
lB lB cB cB cB cB cB
r  lw(5.5m)  c  c  c  c  c.
	_	_	_	_	_	_
	Stage     	Target	Safe	Copies	User	Std
	_	_	_	_	_	_
	trebuchet	xeon	no	no	yes	yes
	runexp  	login	no	no	yes	yes
	isolate 	login	no	no	no	yes
	experiment	login	yes	no	no	yes
	unit    	login	yes	no	no	yes
	sbatch  	login	yes	no	no	yes
	_	_	_	_	_	_
	isolate 	comp	no	no	no	yes
\(rh	\fBcontrol\fP 	comp	yes	no	no	yes
	srun    	comp	yes	no	no	yes
	isolate    	comp	no	yes	no	yes
	_	_	_	_	_	_
	exec    	comp	yes	yes	no	no
	program    	comp	yes	yes	no	no
	_	_	_	_	_	_
.TE
.S P P
.KE
.1C
.\"==================================================================
.NS "Execution stages"
.2C
\fBsrun\fP: launches the tasks in the compute nodes and sets the
affinity.
.P
From here on, all stages are executed in parallel for each task.
.P
The srun program also forks from a SLURM daemon, exiting the
previous isolated namespace.
.\" Go to the next column
.NCOL
.KF
.S 8 14p
.\".S C +0.2v
.TS
center expand;
lB lB cB cB cB cB cB
lB lB cB cB cB cB cB
r  lw(5.5m)  c  c  c  c  c.
	_	_	_	_	_	_
	Stage     	Target	Safe	Copies	User	Std
	_	_	_	_	_	_
	trebuchet	xeon	no	no	yes	yes
	runexp  	login	no	no	yes	yes
	isolate 	login	no	no	no	yes
	experiment	login	yes	no	no	yes
	unit    	login	yes	no	no	yes
	sbatch  	login	yes	no	no	yes
	_	_	_	_	_	_
	isolate 	comp	no	no	no	yes
	control 	comp	yes	no	no	yes
\(rh	\fBsrun\fP    	comp	yes	no	no	yes
	isolate    	comp	no	yes	no	yes
	_	_	_	_	_	_
	exec    	comp	yes	yes	no	no
	program    	comp	yes	yes	no	no
	_	_	_	_	_	_
.TE
.S P P
.KE
.1C
.\"==================================================================
.NS "Execution stages"
.2C
\fBisolate\fP: enter the isolated namespace again.
.P
Now we are ready to execute the program of the experiment.
.\" Go to the next column
.NCOL
.KF
.S 8 14p
.\".S C +0.2v
.TS
center expand;
lB lB cB cB cB cB cB
lB lB cB cB cB cB cB
r  lw(5.5m)  c  c  c  c  c.
	_	_	_	_	_	_
	Stage     	Target	Safe	Copies	User	Std
	_	_	_	_	_	_
	trebuchet	xeon	no	no	yes	yes
	runexp  	login	no	no	yes	yes
	isolate 	login	no	no	no	yes
	experiment	login	yes	no	no	yes
	unit    	login	yes	no	no	yes
	sbatch  	login	yes	no	no	yes
	_	_	_	_	_	_
	isolate 	comp	no	no	no	yes
	control 	comp	yes	no	no	yes
	srun    	comp	yes	no	no	yes
\(rh	\fBisolate\fP 	comp	no	yes	no	yes
	_	_	_	_	_	_
	exec    	comp	yes	yes	no	no
	program    	comp	yes	yes	no	no
	_	_	_	_	_	_
.TE
.S P P
.KE
.1C
.\"==================================================================
.NS "Execution stages"
.2C
\fBexec\fP: sets the environment variables and argv of the program.
.P
Additional commands can be specified in the \fCpre\fP and \fCpost\fP
attributes.
.\" Go to the next column
.NCOL
.KF
.S 8 14p
.\".S C +0.2v
.TS
center expand;
lB lB cB cB cB cB cB
lB lB cB cB cB cB cB
r  lw(5.5m)  c  c  c  c  c.
	_	_	_	_	_	_
	Stage     	Target	Safe	Copies	User	Std
	_	_	_	_	_	_
	trebuchet	xeon	no	no	yes	yes
	runexp  	login	no	no	yes	yes
	isolate 	login	no	no	no	yes
	experiment	login	yes	no	no	yes
	unit    	login	yes	no	no	yes
	sbatch  	login	yes	no	no	yes
	_	_	_	_	_	_
	isolate 	comp	no	no	no	yes
	control 	comp	yes	no	no	yes
	srun    	comp	yes	no	no	yes
	isolate 	comp	no	yes	no	yes
	_	_	_	_	_	_
\(rh	\fBexec\fP    	comp	yes	yes	no	no
	program    	comp	yes	yes	no	no
	_	_	_	_	_	_
.TE
.S P P
.KE
.1C
.\"==================================================================
.NS "Execution stages"
.2C
\fBprogram\fP: the path to the program itself.
.P
This stage can be used to do some changes:
.BL
.LI
Set the mpi implementation of all dependencies.
.LI
Pass build options
.LI
Custom packages (nanos6 with jemalloc)
.LE
.\" Go to the next column
.NCOL
.KF
.S 8 14p
.\".S C +0.2v
.TS
center expand;
lB lB cB cB cB cB cB
lB lB cB cB cB cB cB
r  lw(5.5m)  c  c  c  c  c.
	_	_	_	_	_	_
	Stage     	Target	Safe	Copies	User	Std
	_	_	_	_	_	_
	trebuchet	xeon	no	no	yes	yes
	runexp  	login	no	no	yes	yes
	isolate 	login	no	no	no	yes
	experiment	login	yes	no	no	yes
	unit    	login	yes	no	no	yes
	sbatch  	login	yes	no	no	yes
	_	_	_	_	_	_
	isolate 	comp	no	no	no	yes
	control 	comp	yes	no	no	yes
	srun    	comp	yes	no	no	yes
	isolate 	comp	no	yes	no	yes
	_	_	_	_	_	_
	exec    	comp	yes	yes	no	no
\(rh	\fBprogram\fP	comp	yes	yes	no	no
	_	_	_	_	_	_
.TE
.S P P
.KE
.1C
.\"==================================================================
.NS "Execution stages"
.2C
The \fCstdexp.nix\fP file defines standard pipeline. The last two stages
are usually added to complete the pipeline:
.P
.VERBON
pipeline = stdPipeline ++
  [ exec program ];
.VERBOFF
.P
Any stage can be modified to fit a custom experiment.
.\" Go to the next column
.NCOL
.KF
.S 8 14p
.\".S C +0.2v
.TS
center expand;
lB lB cB cB cB cB cB
lB lB cB cB cB cB cB
r  lw(5.5m)  c  c  c  c  c.
	_	_	_	_	_	_
	Stage     	Target	Safe	Copies	User	Std
	_	_	_	_	_	_
	trebuchet	xeon	no	no	yes	yes
	runexp  	login	no	no	yes	yes
	isolate 	login	no	no	no	yes
	experiment	login	yes	no	no	yes
	unit    	login	yes	no	no	yes
	sbatch  	login	yes	no	no	yes
	_	_	_	_	_	_
	isolate 	comp	no	no	no	yes
	control 	comp	yes	no	no	yes
	srun    	comp	yes	no	no	yes
	isolate 	comp	no	yes	no	yes
	_	_	_	_	_	_
\m[white]\(rh\m[]\
	exec    	comp	yes	yes	no	no
	program    	comp	yes	yes	no	no
	_	_	_	_	_	_
.TE
.S P P
.KE
.1C
.\"==================================================================
.NS "Isolated execution"
.2C
The filesystem is \fBnow\fP isolated to prevent irreproducible
scenarios.
.P
The nix store is mounted at /nix and only some other paths are
available like:
.BL
.S -1 1m
.LI
/var/run/munge (required for SLURM)
.LI
/dev, /sys, /proc for MPI comm
.LI
/etc for hosts (FIXME)
.LI
/gpfs/projects/bsc15 to store data
.LE
.S P P
.P
Additional mounts can be requested by using the \fCextraMounts\fP
attribute.
.\" Go to the next column
.NCOL
.KF
.S 8 14p
.\".S C +0.2v
.TS
center expand;
lB lB cB cB cB cB cB
lB lB cB cB cB cB cB
r  lw(5.5m)  c  c  c  c  c.
	_	_	_	_	_	_
	Stage     	Target	Safe	Copies	User	Std
	_	_	_	_	_	_
	trebuchet	xeon	no	no	yes	yes
	runexp  	login	no	no	yes	yes
\(rh	\fBisolate\fP 	login	no	no	no	yes
	experiment	login	yes	no	no	yes
	unit    	login	yes	no	no	yes
	sbatch  	login	yes	no	no	yes
	_	_	_	_	_	_
\(rh	\fBisolate\fP 	comp	no	no	no	yes
	control 	comp	yes	no	no	yes
	srun    	comp	yes	no	no	yes
\(rh	\fBisolate\fP    	comp	no	yes	no	yes
	_	_	_	_	_	_
	exec    	comp	yes	yes	no	no
	program    	comp	yes	yes	no	no
	_	_	_	_	_	_
.TE
.S P P
.KE
.1C
.\"==================================================================
.NS "Generating figures"
The postprocess pipeline takes the results of the execution and produces
figures or tables to be used in a publication.
.DS CB
.PS 5.3
circlerad=0.3;
ellipsewid=1.2;
linewid=0.3;
boxwid=1;
right
box "Experiment"
arrow
ellipse "Execution"
arrow
box "Result"
arrow
ellipse "Postprocess"
arrow
box "Figure"
.PE
.DE
.P
Once the results are available, multiple figures can be created without
re-running the experiment.
.P
The postprocess pipeline is \fBexperimental\fP; there is no standard
yet.
.\"==================================================================
.NS "Executing experiments"
.P
We cannot access MN4 from nix, as it doesn't has the SSH keys nor
network access when building derivations.
.P
The garlic(1) tool is used to run experiments and fetch the results. See
the manual for details.
.P
.VERBON
xeon07$ nix-build -A fig.nbody.small
\&...
/tmp/garlic/1qcc44lx2nxwi7rmr6389sksq3gwy9w5-experiment: not found
Run the experiment and fetch the results with:

\f[CB]garlic -RFv /nix/store/5zhmdzi5mf0mfsran74cxngn07ba522m-trebuchet\fP

See garlic(1) for more details.
cannot continue building /nix/store/jql4...2cb0-resultTree, aborting
.VERBOFF
.\"==================================================================
.NS "Executing experiments"
.P
To run an experiment use \fB-R\fP and provide the trebuchet path:
.P
.VERBON
xeon07$ garlic -Rv /nix/store/5zh...22m-trebuchet
Running experiment 1qcc...9w5-experiment
sbatch: error: spank: x11.so: Plugin file not found
Submitted batch job 12719522
\&...
xeon07$ 
.VERBOFF
.P
Once the experiment is submited, you can leave the session: it will run
in MN4 automatically at some point.

.\"==================================================================
.NS "Executing experiments"
.P
To wait and fetch the results, use \fB-F\fP:
.P
.VERBON
xeon07$ garlic -Fv /nix/store/5zhmd...522m-trebuchet
/mnt/garlic/bsc15557/out/1qc...9w5-experiment: checking units
3qnm6drx5y95kxrr43gnwqz8v4x641c7-unit: running 7 of 10
awd3jzbcw0cwwvjrcrxzjvii3mgj663d-unit: completed
bqnnrwcbcixag0dfflk1zz34zidk97nf-unit: no status
l32097db7hbggvj7l5hz44y1glzz6jcy-unit: no status
n1a26qa13fdz0ih1gg1m0wfcybs71hm9-unit: completed
rywcwvnpz3mk0gyp5dzk94by3q1h3ljp-unit: completed
yl8ygadghd1fyzjwab3csd8hq1q93cw3-unit: completed
\&...
/mn...w5-experiment: \f[CB]execution complete, fetching results\fP
these derivations will be built:
  /nix/store/mqdr...q4z-resultTree.drv
\&...
\f[CB]/nix/store/jql41hms1dr49ipbjcw41i4dj4pq2cb0-resultTree\fP
.VERBOFF
.\"==================================================================
.NS "Execution"
The dependency graph shows the role of the garlic tool:
.DS CB
.PS
scale=1;
circlerad=0.25;
linewid=0.3;
diag=linewid + circlerad;
far=circlerad*3 + linewid*4
circle "Prog"
arrow
E: circle "EP"
R: circle "Result" at E + (far,0)
RUN: circle "Run" at E + (diag,-diag) dashed
FETCH: circle "Fetch" at R + (-diag,-diag) dashed
move to R.e
arrow
P: circle "PP"
arrow
circle "Plot"
arrow dashed from E to RUN chop
arrow dashed from RUN to FETCH chop
arrow dashed from FETCH to R chop
arrow from E to R chop
.PE
.DE
With the two pipelines
.BL
.LI
EP: Execution pipeline
.LI
PP: Postprocess pipeline
.LE
