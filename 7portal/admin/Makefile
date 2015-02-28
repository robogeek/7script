
include ../mk.cfg

SRC_FILES = adminhier.html \
	adminitems.html \
	hieraddnewhier.cgi \
	hiercustom.cgi \
	hierdelhier.cgi \
	hieredithier.cgi \
	hiereditors.cgi \
	hierhiers.cgi \
	hierinstructions.html \
	hieritems.cgi \
	hiermovehier.cgi \
	hiertree.cgi \
	itemedit.cgi \
	itemhiers.cgi \
	itemtree.cgi

DEST_FILES = $(DOC_ROOT_ADMIN)/adminhier.html \
	$(DOC_ROOT_ADMIN)/adminitems.html \
	$(DOC_ROOT_ADMIN)/hieraddnewhier.cgi \
	$(DOC_ROOT_ADMIN)/hiercustom.cgi \
	$(DOC_ROOT_ADMIN)/hierdelhier.cgi \
	$(DOC_ROOT_ADMIN)/hieredithier.cgi \
	$(DOC_ROOT_ADMIN)/hiereditors.cgi \
	$(DOC_ROOT_ADMIN)/hierhiers.cgi \
	$(DOC_ROOT_ADMIN)/hierinstructions.html \
	$(DOC_ROOT_ADMIN)/hieritems.cgi \
	$(DOC_ROOT_ADMIN)/hiermovehier.cgi \
	$(DOC_ROOT_ADMIN)/hiertree.cgi \
	$(DOC_ROOT_ADMIN)/itemedit.cgi \
	$(DOC_ROOT_ADMIN)/itemhiers.cgi \
	$(DOC_ROOT_ADMIN)/itemtree.cgi

all install: $(DOC_ROOT_ADMIN) $(DEST_FILES)

$(DOC_ROOT_ADMIN):
	-mkdir -p $@

$(DOC_ROOT_ADMIN)/adminhier.html: adminhier.html
	cp $< $@
$(DOC_ROOT_ADMIN)/adminitems.html: adminitems.html
	cp $< $@
$(DOC_ROOT_ADMIN)/hieraddnewhier.cgi: hieraddnewhier.cgi
	cp $< $@
	chmod +x $@
$(DOC_ROOT_ADMIN)/hiercustom.cgi: hiercustom.cgi
	cp $< $@
	chmod +x $@
$(DOC_ROOT_ADMIN)/hierdelhier.cgi: hierdelhier.cgi
	cp $< $@
	chmod +x $@
$(DOC_ROOT_ADMIN)/hieredithier.cgi: hieredithier.cgi
	cp $< $@
	chmod +x $@
$(DOC_ROOT_ADMIN)/hiereditors.cgi: hiereditors.cgi
	cp $< $@
	chmod +x $@
$(DOC_ROOT_ADMIN)/hierhiers.cgi: hierhiers.cgi
	cp $< $@
	chmod +x $@
$(DOC_ROOT_ADMIN)/hierinstructions.html: hierinstructions.html
	cp $< $@
$(DOC_ROOT_ADMIN)/hieritems.cgi: hieritems.cgi
	cp $< $@
	chmod +x $@
$(DOC_ROOT_ADMIN)/hiermovehier.cgi: hiermovehier.cgi
	cp $< $@
	chmod +x $@
$(DOC_ROOT_ADMIN)/hiertree.cgi: hiertree.cgi
	cp $< $@
	chmod +x $@
$(DOC_ROOT_ADMIN)/itemedit.cgi: itemedit.cgi
	cp $< $@
	chmod +x $@
$(DOC_ROOT_ADMIN)/itemhiers.cgi: itemhiers.cgi
	cp $< $@
	chmod +x $@
$(DOC_ROOT_ADMIN)/itemtree.cgi: itemtree.cgi
	cp $< $@
	chmod +x $@
# $(DOC_ROOT_ADMIN)/:
#	cp $< $@

clean: 
	rm -f *~
