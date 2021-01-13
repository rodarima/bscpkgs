.\"usage: NS title
.EQ
delim $$
.EN
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
.ND "January 14, 2021"
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
Garlic experiments
.AF "Barcelona Supercomputing Center"
.AU "Rodrigo Arias Mallo"
.COVEND
.PF "'''%'"
.\" Turn off justification
.SA 0
.\".PF '''%'
.\"==================================================================
.NS "Approach 1"
This was the approach proposed for hybrids PM
.BL
.LI
Perform a granularity experiment with a \fIreasonable\fP problem size.
.LI
Take the best blocksize
.LI
Analyze strong and weak scaling with that blocksize.
.LI
Plot speedup and efficiency comparing multiple PM.
.LE 1
The main problem is that it may lead to \fBbogus comparisons\fP.
Additionally, there is no guarantee that the best blocksize is the one
that performs better with more resources.
.\"==================================================================
.NS "Approach 2"
We want to measure scalability of the application \fBonly\fP, not mixed
with runtime overhead or lack of parallelism.
.P
We define \fBsaturation\fP as the state of an execution that allows a
program to potentially use all the resources (the name comes from the
transistor state, when current flows freely).
.P
Design a new experiment which tests multiple blocksizes and multiple
input sizes to find these states: \fBthe saturation experiment\fP.
.P
Begin with small problems and increase the size, so you get to the
answer quickly.
.\"==================================================================
.NS "Saturation experiment"
.2C
\X'pdf: pdfpic sat.png.tk.pdf -R 7c'
.NCOL
.S -1 -3
.BL 1m
.LI
The objetive is to find the minimum input size that allows us to get
meaningful scalability results.
.LI
More precisely, a unit is in \fBsaturation state\fP if the median time
is below the \fBsaturation time limit\fP, currently set to 110% the minimum
median time (red dashed lines).
.LI
An input size is in \fBsaturation zone\fP if it allows at least K=3
consecutive points in the saturation state.
.LI
With less than 512 particles/CPU (green line) we cannot be sure that the
performance is not impacted by the runtime overhead or lack of
parallelism.
.LE
.S P P
.1C
.\"==================================================================
.NS "Experiment space"
.2C
\X'pdf: pdfpic scaling-region.svg.tk.pdf -L 7c'
.NCOL
.S -1 -3
.BL 1m
.LI
\fBSaturation limit\fP: small tasks cannot be solved without overhead
from the runtime, no matter the blocksize.
.LI
Different limits for OmpSs-2 and OpenMP.
.LI
Experiment A will show the scaling of the app while in the saturation
zone.
.LI
Experiment B will show that OpenMP scales bad in the last 2 points.
.LI
Experiment C will show that at some point both OpenMP and OmpSs-2 scale
bad.
.LE
.S P P
.1C
.\"==================================================================
.NS "Experiment space: experiment C"
.2C
\X'pdf: pdfpic scalability.svg.tk.pdf -L 7c'
.NCOL
.BL 1m
.LI
The experiment C will show a difference in performance when approached
to the saturation limit.
.LI
We could say that OmpSs-2 introduces less overhead, therefore allows
better scalability.
.LE
.1C
.\"==================================================================
.NS "Reproducibility"
How easy can we get the same results? Three properties R0 < R1 < R2 (no common nomenclature yet!):
.BL 1m
.LI
R0: \fBSame\fP humans on the \fBsame\fP machine obtain the same result
.LI
R1: \fBDifferent\fP humans on the \fBsame\fP machine obtain the same result
.LI
R2: \fBDifferent\fP humans on a \fBdifferent\fP machine obtain same result
.LE
.P
Garlic provides 2 types of properties: for software and for experimental
results:
.BL 1m
.LI
Software is R2: you can get the exact same software by any one, in any
machine
.LI
Experimental results are R1: you cannot change the machine MN4 (yet)
.LE
.P
Same experimental result means that the mean of your results is in the confidence
interval of our results \fBand the relative std is < 1%\fP.
