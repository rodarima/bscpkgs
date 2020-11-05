all: execution.pdf execution.ascii pp.pdf pp.ascii

TTYOPT=-rPO=4m -rLL=72m
#TTYOPT=-dpaper=a0 -rPO=4m -rLL=72m

%.pdf: %.ms
	REFER=ref.i groff -ms -dpaper=a4 -k -t -p -R -Tpdf $^ > $@
	-killall -HUP mupdf

%.utf8: %.ms
	REFER=ref.i groff -ms -t -p -R $(TTYOPT) -Tutf8 $^ > $@

%.ascii: %.ms
	REFER=ref.i groff -ms -t -p -R $(TTYOPT) -Tascii $^ > $@
