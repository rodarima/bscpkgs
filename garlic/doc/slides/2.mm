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
.NS "Overview"
Dependency graph of a complete experiment that produces a figure. Each box
is a derivation and arrows represent \fBbuild dependencies\fP.
.DS CB
.S -3.5
.PS
circlerad=0.3;
linewid=0.3;
boxwid=0.52;
boxht=0.35;
fillval=0.2;
right
P: box "Program"
arrow
box "..."
arrow
T: box "Trebuchet"
arrow
box "Result" "(MN4)" dashed
arrow
R: box "ResultTree"
arrow
box "..."
arrow
F: box "Figure"
arrow <-> from P.nw + (0, 0.2) to T.ne + (0, 0.2) \
"Execution pipeline (EP)" above
arrow <-> from R.nw + (0, 0.2) to F.ne + (0, 0.2) \
"Postprocess pipeline (PP)" above
.PE
.S P P
.DE
.P
The \fBResult\fP is not covered by nix (yet). This is what it looks like
when executed:
.DS CB
.S -3.5
.PS
circlerad=0.25;
linewid=0.3;
boxwid=0.52;
boxht=0.35;
fillval=0.2;
right
circle "Build EP"
arrow
circle "Run EP"
arrow
box "Result" "(MN4)" dashed
arrow
circle "Fetch"
arrow
R: box "ResultTree"
arrow
circle "Build PP"
arrow
F: box "Figure"
.PE
.S P P
.DE
.P
Notice dependency order is not the same as execution order.
.\"==================================================================
.NS "Building the execution pipeline (EP)"
.DS CB
.S -3.5
.PS
circlerad=0.25;
linewid=0.3;
boxwid=0.52;
boxht=0.35;
fillval=0.2;
right
B: circle "Build EP" fill
arrow
R: circle "Run EP"
arrow
box "Result" "(MN4)" dashed
arrow
circle "Fetch"
arrow
box "ResultTree"
arrow
circle "Build PP"
arrow
F: box "Figure"
arrow from B.w + (0, 0.35) to F.e + (0, 0.35) \
"Order or execution" above
.PE
.S P P
.DE
.P
Run nix-build with the experiment name:
.P
.VERBON
xeon07$ nix-build -A exp.nbody.baseline
\&...
/nix/store/5zhmdzi5mf0mfsran74cxngn07ba522m-trebuchet
.VERBOFF
.P
Outputs the first stage (the trebuchet). All other stages
are built as dependencies, as they are required to build the trebuchet.
.\"==================================================================
.NS "Running the EP"
.DS CB
.S -3.5
.PS
circlerad=0.25;
linewid=0.3;
boxwid=0.52;
boxht=0.35;
fillval=0.2;
right
B: circle "Build EP"
arrow
R: circle "Run EP" fill
arrow
box "Result" "(MN4)" dashed
arrow
circle "Fetch"
arrow
box "ResultTree"
arrow
circle "Build PP"
arrow
F: box "Figure"
circlerad=0.2;
linewid=0.3;
T: circle at B + (0,-1.3) "trebu."
arrow
circle "runexp"
arrow
circle "isolate"
arrow
circle "exp."
arrow
circle "..."
arrow
circle "exec"
arrow
P: circle "program"
line from R.sw to T.nw dashed
line from R.se to P.n dashed
arrow <-> from T.w - (0, 0.35) to P.e - (0, 0.35) \
"Execution pipeline stages" below
arrow from B.w + (0, 0.35) to F.e + (0, 0.35) \
"Order or execution" above
.PE
.S P P
.DE
.SP 1m
.P
The stages are launched sequentially. Let see what happens in each one.
.\"==================================================================
.NS "Execution pipeline"
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
.P
Sorted by the \fBexecution order\fP.
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
\(rh	\fBtrebuchet\fP	xeon	no	no	yes	\fByes\fP
\(rh	\fBrunexp\fP  	login	no	no	yes	\fByes\fP
\(rh	\fBisolate\fP 	login	no	no	no	\fByes\fP
\(rh	\fBexperiment\fP	login	yes	no	no	\fByes\fP
\(rh	\fBunit\fP    	login	yes	no	no	\fByes\fP
\(rh	\fBsbatch\fP  	login	yes	no	no	\fByes\fP
	_	_	_	_	_	_
\(rh	\fBisolate\fP 	comp	no	no	no	\fByes\fP
\(rh	\fBcontrol\fP 	comp	yes	no	no	\fByes\fP
\(rh	\fBsrun\fP    	comp	yes	no	no	\fByes\fP
\(rh	\fBisolate\fP 	comp	no	yes	no	\fByes\fP
	_	_	_	_	_	_
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
.NS "Running the EP"
.DS CB
.S -3.5
.PS
circlerad=0.25;
linewid=0.3;
boxwid=0.52;
boxht=0.35;
fillval=0.2;
right
B: circle "Build EP"
arrow
R: circle "Run EP" fill
arrow
box "Result" "(MN4)" dashed
arrow
circle "Fetch"
arrow
box "ResultTree"
arrow
circle "Build PP"
arrow
F: box "Figure"
arrow from B.w + (0, 0.35) to F.e + (0, 0.35) \
"Order or execution" above
.PE
.S P P
.DE
.P
We cannot access MN4 from nix, as it doesn't has the SSH keys nor
network access when building derivations.
.P
The garlic(1) tool is used to run experiments and fetch the results. See
the manual for details.
.\"==================================================================
.NS "Running the EP"
.DS CB
.S -3.5
.PS
circlerad=0.25;
linewid=0.3;
boxwid=0.52;
boxht=0.35;
fillval=0.2;
right
B: circle "Build EP"
arrow
R: circle "Run EP" fill
arrow
box "Result" "(MN4)" dashed
arrow
circle "Fetch"
arrow
box "ResultTree"
arrow
circle "Build PP"
arrow
F: box "Figure"
arrow from B.w + (0, 0.35) to F.e + (0, 0.35) \
"Order or execution" above
.PE
.S P P
.DE
.P
To launch the EP use \fBgarlic -R\fP and provide the trebuchet path:
.P
.VERBON
.S -2
xeon07$ garlic -Rv /nix/store/5zhmdzi5mf0mfsran74cxngn07ba522m-trebuchet
Running experiment 1qcc...9w5-experiment
sbatch: error: spank: x11.so: Plugin file not found
Submitted batch job 12719522
\&...
xeon07$ 
.S P P
.VERBOFF
.P
Once the jobs are submited, you can leave the session: it will run
in MN4 automatically at some point.

.\"==================================================================
.NS "Execution complete"
.DS CB
.S -3.5
.PS
circlerad=0.25;
linewid=0.3;
boxwid=0.52;
boxht=0.35;
fillval=0.2;
right
B: circle "Build EP"
arrow
R: circle "Run EP"
arrow
box "Result" "(MN4)" dashed fill
arrow
circle "Fetch"
arrow
box "ResultTree"
arrow
circle "Build PP"
arrow
F: box "Figure"
arrow from B.w + (0, 0.35) to F.e + (0, 0.35) \
"Order or execution" above
.PE
.S P P
.DE
.P
When the EP is complete, the generated results are stored in MN4.
.P
As stated previously, nix cannot access MN4 (yet), so we need to manually
fetch the results.
.\"==================================================================
.NS "Fetching the results"
.DS CB
.S -3.5
.PS
circlerad=0.25;
linewid=0.3;
boxwid=0.52;
boxht=0.35;
fillval=0.2;
right
B: circle "Build EP"
arrow
R: circle "Run EP"
arrow
box "Result" "(MN4)" dashed
arrow
circle "Fetch" fill
arrow
box "ResultTree"
arrow
circle "Build PP"
arrow
F: box "Figure"
arrow from B.w + (0, 0.35) to F.e + (0, 0.35) \
"Order or execution" above
.PE
.S P P
.DE
.P
To fetch the results, use \fBgarlic -F\fP:
.P
.VERBON
.S -3.5
xeon07$ garlic -Fv /nix/store/5zhmdzi5mf0mfsran74cxngn07ba522m-trebuchet
/mnt/garlic/bsc15557/out/1qc...9w5-experiment: checking units
3qnm6drx5y95kxrr43gnwqz8v4x641c7-unit: running 7 of 10
awd3jzbcw0cwwvjrcrxzjvii3mgj663d-unit: completed
bqnnrwcbcixag0dfflk1zz34zidk97nf-unit: no status
\&...
/mn...w5-experiment: \f[CB]execution complete, fetching results\fP
these derivations will be built:
  /nix/store/mqdr...q4z-resultTree.drv
\&...
\f[CB]/nix/store/jql41hms1dr49ipbjcw41i4dj4pq2cb0-resultTree\fP
.S P P
.VERBOFF
.P
Notice that if the experiments are still running, it waits for the
completion of all units first.
.\"==================================================================
.NS "Fetching the results"
.DS CB
.S -3.5
.PS
circlerad=0.25;
linewid=0.3;
boxwid=0.52;
boxht=0.35;
fillval=0.2;
right
B: circle "Build EP"
arrow
R: circle "Run EP"
arrow
box "Result" "(MN4)" dashed
arrow
circle "Fetch"
arrow
box "ResultTree" fill
arrow
circle "Build PP"
arrow
F: box "Figure"
arrow from B.w + (0, 0.35) to F.e + (0, 0.35) \
"Order or execution" above
.PE
.S P P
.DE
.P
.VERBON
.S -3.5
\&...
\f[CB]/nix/store/jql41hms1dr49ipbjcw41i4dj4pq2cb0-resultTree\fP
.S P P
.VERBOFF
.P
When the fetch operation success, the \fBresultTree\fP derivation is
built, with the \fBlogs\fP of the execution.
.P
All other generated data is \fBignored by now\fP, as we don't want to
store large files in the nix store of xeon07.
.\"==================================================================
.NS "Running and fetching"
.DS CB
.S -3.5
.PS
circlerad=0.25;
linewid=0.3;
boxwid=0.52;
boxht=0.35;
fillval=0.2;
right
B: circle "Build EP"
arrow
R: circle "Run EP" fill
arrow
box "Result" "(MN4)" dashed fill
arrow
circle "Fetch" fill
arrow
box "ResultTree" fill
arrow
circle "Build PP"
arrow
F: box "Figure"
arrow from B.w + (0, 0.35) to F.e + (0, 0.35) \
"Order or execution" above
.PE
.S P P
.DE
.P
You can run an experiment and fetch the results with \fBgarlic -RF\fP in
one go:
.P
.VERBON
.S -2
xeon07$ garlic -RF /nix/store/5zhmdzi5mf0mfsran74cxngn07ba522m-trebuchet
.S P P
.VERBOFF
.P
Remember that you can interrupt the fetching while is waiting, and come
later if the experiment takes too long.
.P
If nix tries to build \fBResultTree\fP and doesn't find the experiment
results, it will tell you to run this command to run and fetch the
experiment. Example: building the figure before running the experiment:
.P
.VERBON
.S -2
xeon07$ nix-build -A fig.nbody.baseline
.S P P
.VERBOFF
.\"==================================================================
.NS "Postprocess pipeline (PP)"
.DS CB
.S -3.5
.PS
circlerad=0.25;
linewid=0.3;
boxwid=0.52;
boxht=0.35;
fillval=0.2;
right
B: circle "Build EP"
arrow
R: circle "Run EP"
arrow
box "Result" "(MN4)" dashed
arrow
circle "Fetch"
arrow
box "ResultTree"
arrow
circle "Build PP" fill
arrow
F: box "Figure"
arrow from B.w + (0, 0.35) to F.e + (0, 0.35) \
"Order or execution" above
.PE
.S P P
.DE
.P
Once the \fBresultTree\fP derivation is built, multiple figures can be created
without re-running the experiment.
.P
The postprocess pipeline is formed of several stages as well, but is
considered \fBexperimental\fP; there is no standard yet.
.P
It only needs to be built, as nix can perform all tasks to create the
figures (no manual intervention)
.\"==================================================================
.NS "Building the postprocess pipeline (PP)"
.DS CB
.S -3.5
.PS
circlerad=0.25;
linewid=0.3;
boxwid=0.52;
boxht=0.35;
fillval=0.2;
right
B: circle "Build EP"
arrow
circle "Run EP"
arrow
box "Result" "(MN4)" dashed
arrow
circle "Fetch"
arrow
R: box "ResultTree"
arrow
PP: circle "Build PP" fill
arrow
F: box "Figure"
circlerad=0.2;
linewid=0.3;
T: box at R + (-0.02,-0.8) "timetable"
arrow
box "merge"
arrow
P: box "rPlot"
line from PP.sw to T.n dashed
line from PP.se to P.n dashed
arrow <-> from T.w - (0, 0.35) to P.e - (0, 0.35) \
 "Execution pipeline stages" below
arrow from B.w + (0, 0.35) to F.e + (0, 0.35) \
 "Order or execution" above
.PE
.S P P
.DE
.P
To build the figure, only three stages are required: timetable, merge
and rPlot.
.\"==================================================================
.NS "PP stages: timetable"
.DS CB
.S -3.5
.PS
circlerad=0.25;
linewid=0.3;
boxwid=0.52;
boxht=0.35;
fillval=0.2;
right
box "timetable" fill
arrow
box "merge"
arrow
P: box "rPlot"
.PE
.S P P
.DE
.P
The timetable transforms the logs of the execution into a NDJSON file,
which contains all the unit configuration and the execution time in one
line in JSON:
.P
.VERBON
.S -2
{ "unit":"...", "experiment":"...", "run":1, "config":{...}, "time":1.2345 }
{ "unit":"...", "experiment":"...", "run":2, "config":{...}, "time":1.2333 }
{ "unit":"...", "experiment":"...", "run":3, "config":{...}, "time":1.2323 }
.S P P
.VERBOFF
.P
This format allows R (and possibly other programs) to load \fBall\fP
information regarding the experiment configuration into a table.
.P
It requires the execution logs to contain a line with the time:
.P
.VERBON
.S -2
time 1.2345
.S P P
.VERBOFF
.\"==================================================================
.NS "PP stages: merge"
.DS CB
.S -3.5
.PS
circlerad=0.25;
linewid=0.3;
boxwid=0.52;
boxht=0.35;
fillval=0.2;
right
box "timetable"
arrow
box "merge" fill
arrow
P: box "rPlot"
.PE
.S P P
.DE
.P
The merge stage allows multiple results of several experiments to be
merged in one dataset.
.P
In this way, multiple results can be presented in one figure.
.P
It simple concatenates all the NDJSON files together.
.P
This stage can be build directly with:
.P
.VERBON
$ nix-build ds.nbody.baseline
.VERBOFF
.P
So you can inspect the dataset and play with it before generating the
plots (is automatically built by nix as a dependency).
.\"==================================================================
.NS "PP stages: rPlot"
.DS CB
.S -3.5
.PS
circlerad=0.25;
linewid=0.3;
boxwid=0.52;
boxht=0.35;
fillval=0.2;
right
box "timetable"
arrow
box "merge"
arrow
P: box "rPlot" fill
.PE
.S P P
.DE
.P
Finally, the rPlot stage runs a R script that loads the NDJSON dataset
and generates some plots.
.\"==================================================================
.NS "Building the figures"
.DS CB
.S -3.5
.PS
circlerad=0.25;
linewid=0.3;
boxwid=0.52;
boxht=0.35;
fillval=0.2;
right
B: circle "Build EP"
arrow
circle "Run EP"
arrow
box "Result" "(MN4)" dashed
arrow
circle "Fetch"
arrow
R: box "ResultTree"
arrow
PP: circle "Build PP"
arrow
F: box "Figure" fill
arrow from B.w + (0, 0.35) to F.e + (0, 0.35) \
 "Order or execution" above
.PE
.S P P
.DE
.P
The complete PP and the figures can be build by using:
.P
.VERBON
xeon07$ nix-build -A fig.nbody.baseline
.VERBOFF
.P
A interactive R shell can be used to play with the presentation of the
plots:
.P
.VERBON
xeon07$ nix-shell garlic/fig/dev/shell.nix
$ cp /nix/store/...-merge.json input.json
$ R
> source("garlic/fig/nbody/baseline.R")
.VERBOFF
.P
More about this later.
.\"==================================================================
.NS "Figure dependencies"
.DS CB
.S -3.5
.PS
circlerad=0.3;
linewid=0.3;
boxwid=0.52;
boxht=0.35;
fillval=0.2;
right
P: box "Program"
arrow
box "..."
arrow
T: box "Trebuchet"
arrow
box "Result" "(MN4)" dashed
arrow
R: box "ResultTree"
arrow
box "..."
arrow
F: box "Figure" fill
arrow <-> from P.nw + (0, 0.2) to T.ne + (0, 0.2) \
"Execution pipeline (EP)" above
arrow <-> from R.nw + (0, 0.2) to F.ne + (0, 0.2) \
"Postprocess pipeline (PP)" above
.PE
.S P P
.DE
.P
The figure contains as dependencies all the EP, results and PP.
.P
Any change in any of the stages (or dependencies) will lead to a new
figure, \fBautomatically\fP.
.P
Figures contain the hash of the dataset in the title, so they can
be tracked.
.\"==================================================================
.NS "Article with figures"
.P
An example LaTeX document uses the name of the figures in nix:
.P
.VERBON
  \\includegraphics[]{@fig.nbody.small@/scatter.png}
.VERBOFF
.P
Then, nix will extract all figure references, build them (re-running the
experiment if required) and build the report: \fC$ nix-build
garlic.report\fP
.P
We also have \fBreportTar\fP that puts the figures, LaTeX sources and
a Makefile required to build the report into a self-contained tar.gz.
.P
It can be compiled with \fBmake\fP (no nix required) so it can be sent
to a journal for further changes in the LaTeX source.
.\"==================================================================
.NS "Other changes"
.DL
.LI
We can provide the complete benchmark and BSC packages as a simple
overlay. This allows others to load their own changes on top or below our
benchmark.
.LI
We now avoid reevaluation of nixpkgs when setting the MPI
implementation (allows faster evaluations: 2 s/unit \(-> 2 s total).
.LI
Dependencies between experiments results are posible (experimental):
allows generation of a dataset + computation with dependencies.
.LE
.\"==================================================================
.NS "Questions?"
.defcolor gray rgb #bbbbbb
\m[gray]
.P
Example questions:
.DL
.LI
What software was used to build this presentation?
.LI
I used groff.
.LI
And the diagrams?
.LI
Same :-D
.LI
How long takes to build?
.LI
0,39s user 0,02s system 129% cpu 0,316 total
.LE
\m[]
