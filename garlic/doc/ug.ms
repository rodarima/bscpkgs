.ds HP "21 16 13 12 0 0 0 0 0 0 0 0 0 0"
.nr Ej 1
.nr Hb 3
.nr Hs 3
.S 11p 1.3m
.PH "''''"
.PF "''''"
.PGFORM 14c 29c 3.5c
.\".COVER
.\".de cov@print-date
.\".DS C
.\"\\*[cov*new-date]
.\".DE
.\"..
.\".TL
.\".ps 20
.\"Garlic: User guide
.\".AF "Barcelona Supercomputing Center"
.\".AU "Rodrigo Arias Mallo"
.\".COVEND
\&
.SP 3c
.DS C
.S 25 1
Garlic: User guide
.S P P
.SP 1v
.S 12 1.5m
Rodrigo Arias Mallo
.I "Barcelona Supercomputing Center"
\*[curdate]
.S P P
.SP 15c
.S 9 1.5m
Git commit hash
\f(CW\*[gitcommit]\fP
.S P P
.DE
.bp
.PF "''%''"
.\" ===================================================================
.NH 1
Introduction
.PP
The garlic framework provides all the tools to experiment with HPC
programs and produce publication articles.
.\" ===================================================================
.NH 2
Machines and clusters
.PP
Our current setup employs multiple machines to build and execute the
experiments. Each cluster and node has it's own name and will be
different in other clusters. Therefore, instead of using the names of
the machines we use machine classes to generalize our setup. Those
machine clases currently correspond to a physical machine each:
.BL
.LI
.B Builder
(xeon07): runs the nix-daemon and performs the builds in /nix. Requires
root access to setup de nix-daemon.
.LI 
.B Target
(MareNostrum 4 compute nodes): the nodes where the experiments 
are executed. It doesn't need to have /nix installed or root access.
.LI 
.B Login
(MareNostrum 4 login nodes): used to allocate resources and run jobs. It
doesn't need to have /nix installed or root access.
.LI 
.B Laptop
(where the keyboard is attached): used to connect to the other machines.
No root access is required or /nix, but needs to be able to connect to
the builder.
.LE
.\".P
.\"The specific details of each machine class can be summarized in the
.\"following table:
.\".TS
.\"center;
.\"lB cB cB cB cB lB lB lB
.\"lB  c  c  c  c  l  l  l.
.\"_
.\"Class	daemon	store	root	dl	cpus	space	cluster	node
.\"_
.\"laptop	no	no	no	yes	low	1GB	-	-
.\"build	yes	yes	yes	yes	high	50GB	Cobi	xeon07
.\"login	no	yes	no	no	low	MN4	mn1
.\"target	no	yes	no	no	high	MN4	compute nodes
.\"_
.\".TE
.PP
The machines don't need to be different of each others, as one machine
can implement several classes. For example the laptop can act as the
builder too but is not recommended. Or the login machine can also
perform the builds, but is not possible yet in our setup.
.\" ===================================================================
.H 2 "Properties"
.PP
We can define the following three properties:
.BL 1m
.LI
R0: \fBSame\fP people on the \fBsame\fP machine obtain the same result
.LI
R1: \fBDifferent\fP people on the \fBsame\fP machine obtain the same result
.LI
R2: \fBDifferent\fP people on a \fBdifferent\fP machine obtain the same result
.LE
.PP
The garlic framework distinguishes two classes of results: the result of
building a derivation, which are usually binary programs, and the
results of the execution of an experiment.
.PP
Building a derivation is usually R2, the result is bit-by-bit identical
excepting some rare cases. One example is that during the build process,
a directory is listed by the order of the inodes, giving a random order
which is different between builds. These problems are tracked by the
.I https://r13y.com/
project. In the minimal installation, less than 1% of the derivations
don't achieve the R2 property.
.PP
On the other hand, the results of the experiments are not yet R2, as
they are tied to the target machine.
.\" ===================================================================
.H 1 "Preliminary steps"
The peculiarities of our setup require that users perform some actions
to use the garlic framework. The content of this section is only
intended for the users of our machines, but can serve as reference in
other machines.
.PP
The names of the machine classes are used in the command line prompt
instead of the actual name of the machine, to indicate that the command
needs to be executed in the stated machine class, for example:
.DS I
.VERBON
builder% echo hi
hi
.VERBOFF
.DE
When the machine class is not important, it is ignored and only the
"\f(CW%\fP" prompt appears.
.\" ===================================================================
.H 2 "Configure your laptop"
.PP
To easily connect to the builder (xeon07) in one step, configure the SSH
client to perform a jump over the Cobi login node. The
.I ProxyJump
directive is only available in version 7.3 and upwards. Add the
following lines in the \f(CW\(ti/.ssh/config\fP file of your laptop:
.DS L
\fC
Host cobi
      HostName ssflogin.bsc.es
      User your-username-here
 
Host xeon07
      ProxyJump cobi
      HostName xeon07
      User your-username-here
\fP
.DE
You should be able to connect to the builder typing:
.DS I
.VERBON
laptop$ ssh xeon07
.VERBOFF
.DE
To spot any problems try with the \f(CW-v\fP option to enable verbose
output.
.\" ===================================================================
.H 2 "Configure the builder (xeon07)"
.PP
In order to use nix you would need to be able to download the sources 
from Internet. Usually the download requires the ports 22, 80 and 443 
to be open for outgoing traffic.
.PP
Check that you have network access in
xeon07 provided by the environment variables \fIhttp_proxy\fP and
\fIhttps_proxy\fP. Try to fetch a webpage with curl, to ensure the proxy
is working:
.DS I
.VERBON
  xeon07$ curl x.com
  x
.VERBOFF
.DE
.\" ===================================================================
.H 3 "Create a new SSH key"
.PP
There is one DSA key in your current home called "cluster" that is no
longer supported in recent SSH versions and should not be used. Before
removing it, create a new one without password protection leaving the
passphrase empty (in case that you don't have one already created) by
running:
.DS I
.VERBON
xeon07$ ssh-keygen
Generating public/private rsa key pair.
Enter file in which to save the key (\(ti/.ssh/id_rsa):
Enter passphrase (empty for no passphrase):
Enter same passphrase again:
Your identification has been saved in \(ti/.ssh/id_rsa.
Your public key has been saved in \(ti/.ssh/id_rsa.pub.
\&...
.VERBOFF
.DE
By default it will create the public key at \f(CW\(ti/.ssh/id_rsa.pub\fP.
Then add the newly created key to the authorized keys, so you can
connect to other nodes of the Cobi cluster:
.DS I
.VERBON
xeon07$ cat \(ti/.ssh/id_rsa.pub >> \(ti/.ssh/authorized_keys
.VERBOFF
.DE
Finally, delete the old "cluster" key:
.DS I
.VERBON
xeon07$ rm \(ti/.ssh/cluster \(ti/.ssh/cluster.pub
.VERBOFF
.DE
And remove the section in the configuration \f(CW\(ti/.ssh/config\fP
where the key was assigned to be used in all hosts along with the
\f(CWStrictHostKeyChecking=no\fP option. Remove the following lines (if
they exist):
.DS I
.VERBON
Host *
    IdentityFile \(ti/.ssh/cluster
    StrictHostKeyChecking=no
.VERBOFF
.DE
By default, the SSH client already searchs for a keypair called
\f(CW\(ti/.ssh/id_rsa\fP and \f(CW\(ti/.ssh/id_rsa.pub\fP, so there is
no need to manually specify them.
.PP
You should be able to access the login node with your new key by using:
.DS I
.VERBON
xeon07$ ssh ssfhead
.VERBOFF
.DE
.\" ===================================================================
.H 3 "Authorize access to the repository"
.PP
The sources of BSC packages are usually downloaded directly from the PM
git server, so you must be able to access all repositories without a
password prompt.
.PP
Most repositories are open to read for logged in users, but there are
some exceptions (for example the nanos6 repository) where you must have
explicitly granted read access.
.PP
Copy the contents of your public SSH key in \f(CW\(ti/.ssh/id_rsa.pub\fP
and paste it in GitLab at
.DS I
.VERBON
https://pm.bsc.es/gitlab/profile/keys
.VERBOFF
.DE
Finally verify the SSH connection to the server works and you get a 
greeting from the GitLab server with your username:
.DS I
.VERBON
xeon07$ ssh git@bscpm03.bsc.es
PTY allocation request failed on channel 0
Welcome to GitLab, @rarias!
Connection to bscpm03.bsc.es closed.
.VERBOFF
.DE
Verify that you can access the nanos6 repository (otherwise you 
first need to ask to be granted read access), at:
.DS I
.VERBON
https://pm.bsc.es/gitlab/nanos6/nanos6
.VERBOFF
.DE
Finally, you should be able to download the nanos6 git 
repository without any password interaction by running:
.DS I
.VERBON
xeon07$ git clone git@bscpm03.bsc.es:nanos6/nanos6.git
.VERBOFF
.DE
Which will create the nanos6 directory.
.\" ===================================================================
.H 3 "Authorize access to MareNostrum 4"
You will also need to access MareNostrum 4 from the xeon07 machine, in 
order to run experiments. Add the following lines to the 
\f(CW\(ti/.ssh/config\fP file and set your user name:
.DS I
.VERBON
Host mn0 mn1 mn2
    User <your user name in MN4>
.VERBOFF
.DE
Then copy your SSH key to MareNostrum 4 (it will ask you for your login
password):
.DS I
.VERBON
xeon07$ ssh-copy-id -i \(ti/.ssh/id_rsa.pub mn1
.VERBOFF
.DE
Finally, ensure that you can connect without a password:
.DS I
.VERBON
xeon07$ ssh mn1
\&...
login1$
.VERBOFF
.DE
.\" ===================================================================
.H 3 "Clone the bscpkgs repository"
.PP
Once you have Internet and you have granted access to the PM GitLab 
repositories you can begin building software with nix. First ensure 
that the nix binaries are available from your shell in xeon07:
.DS I
.VERBON
xeon07$ nix --version
nix (Nix) 2.3.6
.VERBOFF
.DE
Now you are ready to build and install packages with nix. Clone the 
bscpkgs repository:
.DS I
.VERBON
xeon07$ git clone git@bscpm03.bsc.es:rarias/bscpkgs.git
.VERBOFF
.DE
Nix looks in the current folder for a file named \f(CWdefault.nix\fP for
packages, so go to the bscpkgs directory:
.DS I
.VERBON
xeon07$ cd bscpkgs
.VERBOFF
.DE
Now you should be able to build nanos6 (which is probably already
compiled):
.DS I
.VERBON
xeon07$ nix-build -A bsc.nanos6
\&...
/nix/store/...2cm1ldx9smb552sf6r1-nanos6-2.4-6f10a32
.VERBOFF
.DE
The installation is placed in the nix store (with the path stated in 
the last line of the build process), with the \f(CWresult\fP symbolic
link pointing to the same location:
.DS I
.VERBON
xeon07$ readlink result
/nix/store/...2cm1ldx9smb552sf6r1-nanos6-2.4-6f10a32
.VERBOFF
.DE
.\" ===================================================================
.H 2 "Configure the login and target (MareNostrum 4)"
.PP
In order to execute the programs in MareNostrum 4, you first need load
some utilities in the PATH. Add to the end of the file
\f(CW\(ti/.bashrc\fP in MareNostrum 4 the following line:
.DS I
.VERBON
export PATH=/gpfs/projects/bsc15/nix/bin:$PATH
.VERBOFF
.DE
Then logout and login again (our source the \f(CW\(ti/.bashrc\fP file)
and check that now you have the \f(CWnix-develop\fP command available:
.DS I
.VERBON
login1$ which nix-develop
/gpfs/projects/bsc15/nix/bin/nix-develop
.VERBOFF
.DE
The new utilities are available both in the login nodes and in the
compute (target) nodes, as they share the file system over the network.
.\" ===================================================================
.H 1 "Overview"
.PP
The garlic framework is designed to fulfill all the requirements of an
experimenter in all the steps up to publication. The experience gained
while using it suggests that we move along three stages despicted in the
following diagram:
.DS CB
.S 9p 10p
.PS 5
linewid=1;
right
box "Source" "code"
arrow "Development" above
box "Program"
arrow "Experiment" above
box "Results"
arrow "Data" "exploration"
box "Figures"
.PE
.S P P
.DE
In the development phase the experimenter changes the source code in
order to introduce new features or fix bugs. Once the program is
considered functional, the next phase is the experimentation, where
several experiment configurations are tested to evaluate the program. It
is common that some problems are spotted during this phase, which lead
the experimenter to go back to the development phase and change the
source code.
.PP
Finally, when the experiment is considered completed, the
experimenter moves to the next phase, which envolves the exploration of
the data generated by the experiment. During this phase, it is common to
generate results in the form of plots or tables which provide a clear
insight in those quantities of interest. It is also common that after
looking at the figures, some changes in the experiment configuration
need to be introduced (or even in the source code of the program).
.PP
Therefore, the experimenter may move forward and backwards along three
phases several times. The garlic framework provides support for all the
three stages (with different degrees of madurity).
.H 1 "Development (work in progress)"
.PP
During the development phase, a functional program is produced by
modifying its source code. This process is generally cyclic: the
developer needs to compile, debug and correct mistakes. We want to
minimize the delay times, so the programs can be executed as soon as
needed, but under a controlled environment so that the same behavior
occurs during the experimentation phase.
.PP
In particular, we want that several developers can reproduce the
the same development environment so they can debug each other programs
when reporting bugs. Therefore, the environment must be carefully
controlled to avoid non-reproducible scenarios.
.PP
The current development environment provides an isolated shell with a
clean environment, which runs in a new mount namespace where access to
the filesystem is restricted. Only the project directory and the nix
store are available (with some other exceptions), to ensure that you
cannot accidentally link with the wrong library or modify the build
process with a forgotten environment variable in the \f(CW\(ti/.bashrc\fP
file.
.\" ===================================================================
.H 2 "Getting the development tools"
.PP
To create a development
environment, first copy or download the sources of your program (not the
dependencies) in a new directory placed in the target machine
(MareNostrum\~4).
.PP
The default environment contains packages commonly used to develop
programs, listed in the \fIgarlic/index.nix\fP file:
.\" FIXME: Unify garlic.unsafeDevelop in garlic.develop, so we can
.\" specify the packages directly
.DS I
.VERBON
develop = let 
  commonPackages = with self; [
    coreutils htop procps-ng vim which strace
    tmux gdb kakoune universal-ctags bashInteractive
    glibcLocales ncurses git screen curl
    # Add more nixpkgs packages here...
  ];  
  bscPackages = with bsc; [
    slurm clangOmpss2 icc mcxx perf tampi impi
    # Add more bsc packages here...
  ];
  ...
.VERBOFF
.DE
If you need additional packages, add them to the list, so that they
become available in the environment. Those may include any dependency
required to build your program.
.PP
Then use the build machine (xeon07) to build the
.I garlic.develop
derivation:
.DS I
.VERBON
build% nix-build -A garlic.develop
\&...
build% grep ln result
ln -fs /gpfs/projects/.../bin/stage1 .nix-develop
.VERBOFF
.DE
Copy the \fIln\fP command and run it in the target machine
(MareNostrum\~4), inside the new directory used for your program
development, to create the link \fI.nix-develop\fP (which is used to
remember your environment). Several environments can be stored in
different directories using this method, with different packages in each
environment. You will need
to rebuild the
.I garlic.develop
derivation and update the
.I .nix-develop
link after the package list is changed. Once the
environment link is created, there is no need to repeat these steps again.
.PP
Before entering the environment, you will need to access the required
resources for your program, which may include several compute nodes.
.\" ===================================================================
.H 2 "Allocating resources for development"
.PP
Our target machine (MareNostrum 4) provides an interactive shell, that
can be requested with the number of computational resources required for
development. To do so, connect to the login node and allocate an
interactive session:
.DS I
.VERBON
% ssh mn1
login% salloc ...
target%
.VERBOFF
.DE
This operation may take some minutes to complete depending on the load
of the cluster. But once the session is ready, any subsequent execution
of programs will be immediate.
.\" ===================================================================
.H 2 "Accessing the developement environment"
.PP
The utility program \fInix-develop\fP has been designed to access the
development environment of the current directory, by looking for the
\fI.nix-develop\fP file. It creates a namespace where the required
packages are installed and ready to be used. Now you can access the
newly created environment by running:
.DS I
.VERBON
target% nix-develop
develop%
.VERBOFF
.DE
The spawned shell contains all the packages pre-defined in the
\fIgarlic.develop\fP derivation, and can now be accessed by typing the
name of the commands.
.DS I
.VERBON
develop% which gcc
/nix/store/azayfhqyg9...s8aqfmy-gcc-wrapper-9.3.0/bin/gcc
develop% which gdb
/nix/store/1c833b2y8j...pnjn2nv9d46zv44dk-gdb-9.2/bin/gdb
.VERBOFF
.DE
If you need additional packages, you can add them in the
\fIgarlic/index.nix\fP file as mentioned previously. To keep the
same current resources, so you don't need to wait again for the
resources to be allocated, exit only from the development shell:
.DS I
.VERBON
develop% exit
target%
.VERBOFF
.DE
Then update the
.I .nix-develop
link and enter into the new develop environment:
.DS I
.VERBON
target% nix-develop
develop%
.VERBOFF
.DE
.\" ===================================================================
.H 2 "Execution"
The allocated shell can only execute tasks in the current node, which
may be enough for some tests. To do so, you can directly run your
program as:
.DS I
.VERBON
develop$ ./program
.VERBOFF
.DE
If you need to run a multi-node program, typically using MPI
communications, then you can do so by using srun. Notice that you need
to allocate several nodes when calling salloc previously. The srun
command will execute the given program \fBoutside\fP the development
environment if executed as-is. So we re-enter the develop environment by
calling nix-develop as a wrapper of the program:
.\" FIXME: wrap srun to reenter the develop environment by its own
.DS I
.VERBON
develop$ srun nix-develop ./program
.VERBOFF
.DE
.\" ===================================================================
.H 2 "Debugging"
The debugger can be used to directly execute the program if is executed
in only one node by using:
.DS I
.VERBON
develop$ gdb ./program
.VERBOFF
.DE
Or it can be attached to an already running program by using its PID.
You will need to first connect to the node running it (say target2), and
run gdb inside the nix-develop environment. Use
.I squeue
to see the compute nodes running your program: 
.DS I
.VERBON
login$ ssh target2
target2$ cd project-develop
target2$ nix-develop
develop$ gdb -p $pid
.VERBOFF
.DE
You can repeat this step to control the execution of programs running in
different nodes simultaneously.
.PP
In those cases where the program crashes before being able to attach the
debugger, enable the generation of core dumps:
.DS I
.VERBON
develop$ ulimit -c unlimited
.VERBOFF
.DE
And rerun the program, which will generate a core file that can be
opened by gdb and contains the state of the memory when the crash
happened. Beware that the core dump file can be very large, depending on
the memory used by your program at the crash.
.H 2 "Git branch name convention"
.PP
The garlic benchmark imposes a set of requirements to be meet for each 
application in order to coordinate the execution of the benchmark and 
the gathering process of the results.
.PP
Each application must be available in a git repository so it can be 
included into the garlic benchmark. The different combinations of 
programming models and communication schemes should be each placed in 
one git branch, which are referred to as \fIbenchmark branches\fP. At
least one benchmark branch should exist and they all must begin with the
prefix \f(CWgarlic/\fP (other branches will be ignored).
.PP
The branch name is formed by adding keywords separated by the "+" 
character. The keywords must follow the given order and can only 
appear zero or once each. At least one keyword must be included. The 
following keywords are available:
.LB 12 2 0 0
.LI \f(CWmpi\fP
A significant fraction of the communications uses only the standard MPI
(without extensions like TAMPI).
.LI \f(CWtampi\fP
A significant fraction of the communications uses TAMPI.
.LI \f(CWsend\fP
A significant part of the MPI communication uses the blocking family of
methods (MPI_Send, MPI_Recv, MPI_Gather...).
.LI \f(CWisend\fP
A significant part of the MPI communication uses the non-blocking family
of methods (MPI_Isend, MPI_Irecv, MPI_Igather...).
.LI \f(CWrma\fP
A significant part of the MPI communication uses remote memory access
(one-sided) methods (MPI_Get, MPI_Put...).
.LI \f(CWseq\fP
The complete execution is sequential in each process (one thread per
process).
.LI \f(CWomp\fP
A significant fraction of the execution uses the OpenMP programming
model.
.LI \f(CWoss\fP
A significant fraction of the execution uses the OmpSs-2 programming
model.
.LI \f(CWtask\fP
A significant part of the execution involves the use of the tasking
model.
.LI \f(CWtaskfor\fP
A significant part of the execution uses the taskfor construct.
.LI \f(CWfork\fP
A significant part of the execution uses the fork-join model (including
hybrid programming techniques with  parallel computations and sequential
communications).
.LI \f(CWsimd\fP
A significant part of the computation has been optimized to use SIMD
instructions.
.LE
.PP
In the \fBAppendix A\fP there is a flowchart to help the decision
process of the branch name.
.PP
Additional user defined keywords may be added at the end using the 
separator "+" as well. User keywords must consist of capital 
alphanumeric characters only and be kept short. These additional 
keywords must be different (case insensitive) to the already defined 
above. Some examples:
.DS I
.VERBON
garlic/mpi+send+seq
garlic/mpi+send+omp+fork
garlic/mpi+isend+oss+task
garlic/tampi+isend+oss+task
garlic/tampi+isend+oss+task+COLOR
garlic/tampi+isend+oss+task+COLOR+BTREE
.VERBOFF
.DE
.\" ===================================================================
.H 1 "Experimentation"
The experimentation phase begins with a functional program which is the
object of study. The experimenter then designs an experiment aimed at
measuring some properties of the program. The experiment is then
executed and the results are stored for further analysis.
.H 2 "Writing the experiment configuration"
.PP
The term experiment is quite overloaded in this document. We are going
to see how to write the recipe that describes the execution pipeline of
an experiment.
.PP
Within the garlic benchmark, experiments are typically sorted by a
hierarchy depending on which application they belong. Take a look at the
\fCgarlic/exp\fP directory and you will find some folders and .nix
files.
.PP
Each of those recipes files describe a function that returns a
derivation, which, once built will result in the first stage script of
the execution pipeline.
.PP
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
.PP
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
.PP
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
.PP
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
.PP
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
.PP
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
.PP
By following this rule, the experiments can easily be ported to machines
with other hardware characteristics, and we only need to define the
hardware details once. Then all the experiments will be updated based on
those details.
.H 2 "First steps"
.PP
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
.PP
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
.PP
As you gain confidence over that the execution went as planned, begin
increasing the problem size, the number of runs, the time limit and
lastly the number of units. The rationale is that each unit that is
shared among experiments gets assigned the same hash. Therefore, you can
iteratively add more units to an experiment, and if they are already
executed (and the results were generated) is reused.
.SK
.APP "" "Branch name diagram"
.DS CB
.S -3 10
.PS 4.4/25.4
copy "gitbranch.pic"
.PE
.S P P
.DE
.TC
