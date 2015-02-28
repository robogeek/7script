
include ../mk.cfg

SRC_FILES = pkgIndex.tcl \
	site.tcl \
	tree.tcl

DEST_FILES = $(SITE_INSTALL_DIR)/site/pkgIndex.tcl \
	$(SITE_INSTALL_DIR)/site/site.tcl \
	$(SITE_INSTALL_DIR)/site/tree.tcl

all install: $(SITE_INSTALL_DIR)/site $(DEST_FILES)

 $(SITE_INSTALL_DIR)/site: 
	-mkdir -p  $@

$(SITE_INSTALL_DIR)/site/pkgIndex.tcl: pkgIndex.tcl
	cp $< $@

$(SITE_INSTALL_DIR)/site/site.tcl: site.tcl
	cp $< $@

$(SITE_INSTALL_DIR)/site/tree.tcl: tree.tcl
	cp $< $@

clean:
	rm -f *~

