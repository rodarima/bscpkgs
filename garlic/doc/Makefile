all: execution.pdf execution.utf8 execution.ascii pp.pdf pp.utf8 pp.ascii\
	branch.pdf blackbox.pdf ug.pdf

TTYOPT=-rPO=4m -rLL=72m
PDFOPT=-dpaper=a4 -rPO=4c -rLL=13c
#MMOPT=-dpaper=a4 -rpo=5c -rll=13c
PREPROC=-k -t -p -R
POSTPROC=
# Embed fonts?
#POSTPROC+=-P -e

blackbox.pdf: blackbox.ms Makefile
	REFER=ref.i groff -ms $(PREPROC) -dpaper=a4 -rPO=2c -rLL=17c -Tpdf $< > $@

ug.pdf: ug.mm Makefile
	groff -mm $(PREPROC) $(POSTPROC) -dpaper=a4 -Tpdf $< > $@
	-killall -HUP mupdf

%.pdf: %.ms Makefile
	REFER=ref.i groff -ms $(PREPROC) $(PDFOPT) -Tpdf $< > $@
	-killall -HUP mupdf

%.utf8: %.ms
	REFER=ref.i groff -ms $(PREPROC) $(TTYOPT) -Tutf8 $^ > $@

%.ascii: %.ms
	REFER=ref.i groff -ms -c $(PREPROC) $(TTYOPT) -Tascii $^ > $@
