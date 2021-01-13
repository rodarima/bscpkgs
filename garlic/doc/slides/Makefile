GENFIG=scaling-region.svg.tk.pdf \
       sat.png.tk.pdf \
       scalability.svg.tk.pdf
GENPDF=2.pdf 3.pdf

all: $(GENPDF)

keep_figs: $(GENFIG)

%.svg.pdf: %.svg Makefile
	inkscape $< --export-pdf=$@

%.png.pdf: %.png Makefile
	gm convert $< -density 30 $@

%.tk.pdf: %.pdf Makefile
	pdftk $< output $@

%.pdf: %.mm $(GENFIG)
	groff -Tpdf -e -t -p -P-p12c,16c -mm $< > $@
	-killall -HUP mupdf

watch:
	while [ 1 ]; do inotifywait -e modify *; make; done

.PRECIOUS: *.svg.pdf *.tk.pdf

clean:
	rm -f $(GENFIG) $(GENPDF)
