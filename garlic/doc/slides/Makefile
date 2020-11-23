all: test.mm Makefile
	groff -Tpdf -t -p -P-p12c,16c -mm test.mm > test.pdf
	-killall -HUP mupdf

watch:
	while [ 1 ]; do inotifywait -e modify *; make; done
