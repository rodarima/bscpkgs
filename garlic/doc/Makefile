all: execution.pdf execution.txt pp.pdf pp.txt

%.pdf: %.ms
	groff -ms -t -p -Tpdf $^ > $@
	-killall -HUP mupdf

%.txt: %.ms
	groff -ms -t -p -Tutf8 $^ > $@
