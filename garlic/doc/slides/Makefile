all: 2.pdf Makefile

%.pdf: %.mm
	groff -Tpdf -t -p -P-p12c,16c -mm $< > $@
	-killall -HUP mupdf

watch:
	while [ 1 ]; do inotifywait -e modify *; make; done
