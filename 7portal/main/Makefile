
include ../mk.cfg

SRC_FILES = index.cgi

DEST_FILES = $(DOCROOT)/index.cgi

all install: $(DEST_FILES)

$(DOCROOT)/index.cgi: index.cgi
	cp $< $@
	chmod +x $@

clean:
	rm -f *~
