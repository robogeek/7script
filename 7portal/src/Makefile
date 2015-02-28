
include ../mk.cfg

SRC_FILES = pkgIndex.tcl \
	7portal.tcl \
	7tree.tcl \
	7members.tcl

DEST_FILES = $(LIB_INSTALL_DIR)/7portal/pkgIndex.tcl \
	$(LIB_INSTALL_DIR)/7portal/7portal.tcl \
	$(LIB_INSTALL_DIR)/7portal/7tree.tcl \
	$(LIB_INSTALL_DIR)/7portal/7members.tcl

all install: $(LIB_INSTALL_DIR)/7portal $(DEST_FILES)

$(LIB_INSTALL_DIR)/7portal: 
	-mkdir -p  $@

$(LIB_INSTALL_DIR)/7portal/7portal.tcl: 7portal.tcl
	cp $< $@

$(LIB_INSTALL_DIR)/7portal/7tree.tcl: 7tree.tcl
	cp $< $@

$(LIB_INSTALL_DIR)/7portal/7members.tcl: 7members.tcl
	cp $< $@

$(LIB_INSTALL_DIR)/7portal/pkgIndex.tcl: pkgIndex.tcl
	cp $< $@

clean:
	rm -f *~

