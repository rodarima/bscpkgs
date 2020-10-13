all: execution.pdf execution.txt

%.pdf: %.ms
	groff -ms -t -Tpdf $^ > $@
	#killall -HUP mupdf

%.txt: %.ms
	groff -ms -t -Tutf8 $^ > $@
