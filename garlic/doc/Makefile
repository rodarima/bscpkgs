all: ug.pdf ug.html doc.tar.gz

TTYOPT=-rPO=4m -rLL=72m
PDFOPT=-dpaper=a4 -rPO=4c -rLL=13c
#MMOPT=-dpaper=a4 -rpo=5c -rll=13c
PREPROC=-k -t -p -R
POSTPROC=
REGISTERS=-dcurdate="`date '+%Y-%m-%d'`"
REGISTERS+=-dgitcommit="`git rev-parse HEAD`"

PREPROC+=$(REGISTERS)
HTML_OPT=$(PREPROC) -P-y -P-V -P-Dimg -P-i120 -Thtml
# Embed fonts?
#POSTPROC+=-P -e

blackbox.pdf: blackbox.ms Makefile
	REFER=ref.i groff -ms $(PREPROC) -dpaper=a4 -rPO=2c -rLL=17c -Tpdf $< > $@

%.html: %.ms Makefile
	mkdir -p img
	REFER=ref.i groff -ms -mwww $(HTML_OPT) $< > $@
	echo $(HTML_OPT)
	sed -i '/<\/head>/i<link rel="stylesheet" href="s.css">' $@
	sed -i 's/^<a name="\([^"]*\)"><\/a>/<a name="\1" href="#\1">\&sect;<\/a>/g' $@
	#sed -i '/<h1 /,/<hr>/s/^<a href="#[0-9]\+\.[0-9]\+\.[0-9]\+.*//' $@
	sed -i '/<h1 /,/<hr>/s/^<a href="#[0-9]\+\.[0-9]\+.*//' $@

%.pdf: %.ms Makefile
	REFER=ref.i groff -ms -mwww $(PREPROC) $(PDFOPT) -Tpdf $< > $@
	-killall -HUP mupdf

%.utf8: %.ms
	REFER=ref.i groff -ms -mwww $(PREPROC) $(TTYOPT) -Tutf8 $^ > $@

%.ascii: %.ms
	REFER=ref.i groff -ms -mwww -c $(PREPROC) $(TTYOPT) -Tascii $^ > $@

doc.tar.gz: ug.pdf ug.html s.css
	tar czf $@ $^ img s.css

clean:
	rm -rf img ug.pdf ug.html doc.tar.gz
