all: execution.pdf execution.txt

%.pdf: %.ms
	groff -ms -tbl -Tpdf $^ > $@
	#pdfms $^ 2>&1 >$@  | sed 's/^troff: //g'
	killall -HUP mupdf

%.txt: %.ms
	groff -ms -tbl -Tutf8 $^ > $@
