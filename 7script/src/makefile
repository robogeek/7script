# makefile - master control panel for making 7Script
#
# This Makefile requires GNU make.
#
#  -*- makefile -*-

############################
# SET UP DEBUGGING SUPPORT #
############################

# To make the libraries and other binaries debuggable
# they need to be compiled with the right flag.
# Set this to yes/no depending on your needs

COMPILE_WITH_DEBUG = yes

#######################################
# SELECT PLATFORM - GET CONFIGURATION #
#######################################

# The PLATFORM_SELECTOR chooses which platform
# you are compiling on.  These are just names
# that are then used in mk.cfg to select a section
# of configuration parameters.  It is recommended
# that you use the domain name of the host you are
# building this for, then in mk.cfg you create a
# section for your host.

PLATFORM_SELECTOR = xxx-i386-redhat-6.0

#################################
# DECLARE IF WE ARE USING MYSQL #
#################################

# MySQL might not be available on every platform.
# To satisfy that condition, it is made an optional
# piece of compilation.

PLATFORM_USING_MYSQL = yes

# Pull in the definitions needed by the rest of this makefile.
# Anything needed to tailor the options in mk.cfg must be
# defined before this point.
include mk.cfg


###########
# TARGETS #
###########

SCRIPTOBJS = tclAppInit.o scan.o cgic.o grep.o tcl-parse.o 

all:   install-libs 7script

install: install-libs install-7script

7script: ${SCRIPTOBJS}
	$(CC) ${SCRIPTOBJS} ${LDFLAGS} ${DEBUGFLAG} -o 7script

libraries:  lib-tcl lib-memchan lib-gdbm lib-tclgdbm \
	lib-md5 lib-passwd lib-gdft lib-mysql

clean: clean-tcl clean-memchan clean-libgdbm clean-tclgdbm \
	clean-md5 clean-passwd clean-gdft clean-mysql
	rm -f ${SCRIPTOBJS} *.o 7script a.out *~ test.db
	find .. -name '*~' -type f -print  | xargs rm -f
	cd ../tcl; make clean

configure: config-tcl config-memchan config-gdbm config-tclgdbm \
	config-md5 config-passwd config-gdft config-mysql

unconfigure: FORCE
	find .. -name 'config.cache'  -print | xargs rm -f
	find .. -name 'config.status' -print | xargs rm -f
	rm -f $(TCLDIR)/unix/Makefile $(TCLDIR)/unix/tclConfig.sh

install-libs: libraries \
	install-tcl install-memchan install-gdbm install-tclgdbm \
	install-md5 install-passwd install-gdft install-mysql 

install-7script: 7script
	cp 7script ${BIN_INSTALL_DIR}
	cd ../tcl; make LIB_INSTALL_DIR=${LIB_INSTALL_DIR}

test-tcl:
	cd $(TCLDIR)/unix; make test

##################
# CONFIG DETAILS #
##################

config-tcl:
	cd $(TCLDIR)/unix; ./configure --prefix=$(BASEDIR) \
				$(CONFIG_ENABLE_SHARED) \
				$(CONFIG_ENABLE_GCC_IN_TCL)
	cd $(TCLDIR)/unix; make $(PASSED_DEBUG_FLAG); make install
	if [ "$(FIX_TCL_LIB_NAME)" != "no" ]; then \
		( \
		cd $(TCLBASEDIR)/lib; \
		for f in ${FIXED_TCL_LIB_NAMES}; do \
			rm -f $$f; \
			ln ${BASE_TCL_LIB_NAME} $$f; \
		done \
		) \
	fi

#      --with-tcl=$(TCLBASEDIR) 
#      --with-tcl-lib-dir=$(TCLBASEDIR)/lib 

config-memchan:
	cd $(MEMCHANDIR); ./configure --prefix=$(BASEDIR)  \
                                      $(CONFIG_ENABLE_SHARED)

config-gdbm:
	cd $(GDBMDIR);    ./configure --prefix=$(BASEDIR) \
                                      $(CONFIG_ENABLE_SHARED)

config-tclgdbm:
	cd $(TCLGDBMDIR); ./configure --prefix=$(BASEDIR) \
                                      $(CONFIG_ENABLE_SHARED)

config-md5:
	cd $(MD5DIR);     ./configure --prefix=$(BASEDIR) \
                                      $(CONFIG_ENABLE_SHARED)

config-passwd:
	cd $(PASSWDDIR);  ./configure --prefix=$(BASEDIR) \
                                      $(CONFIG_ENABLE_SHARED)

config-gdft:
	cd $(GDFTDIR);    ./configure --prefix=$(BASEDIR) \
                                      $(CONFIG_ENABLE_SHARED)

config-mysql:
ifeq ($(PLATFORM_USING_MYSQL),yes)
	cd $(MYSQLTCLDIR)
endif

###################
# INSTALL DETAILS #
###################

install-tcl: FORCE
	cd $(TCLDIR)/unix; make install

install-memchan: FORCE
	cd $(MEMCHANDIR);  make install

install-gdbm: FORCE
	cd $(GDBMDIR);     make $(PLATFORM_LIBGDBM_INSTALL) install

install-tclgdbm: FORCE
# We only compile tclgdbm.o and don't need to install anything.
#	cd $(TCLGDBMDIR);  make install

install-md5: FORCE
	cd $(MD5DIR);      make install

install-passwd: FORCE
	cd $(PASSWDDIR);   make install

install-gdft: FORCE
	cd $(GDFTDIR);     make install

install-mysql: FORCE
# Only a .a is compiled, there is nothing to install.
#	cd $(MYSQLTCLDIR); make install

#################
# CLEAN DETAILS #
#################

clean-tcl: FORCE
	cd $(TCLDIR)/unix; make clean

clean-memchan: FORCE
	cd $(MEMCHANDIR);  make clean

clean-libgdbm: FORCE
	cd $(GDBMDIR);     make clean

clean-tclgdbm: FORCE
	cd $(TCLGDBMDIR);  make clean

clean-md5: FORCE
	cd $(MD5DIR);      make clean

clean-passwd: FORCE
	cd $(PASSWDDIR);   make clean

clean-gdft: FORCE
	cd $(GDFTDIR);     make clean

clean-mysql: FORCE
	cd $(MYSQLTCLDIR); make clean

################
# DEPENDENCIES #
################

scan.o:       scan.c
tclAppInit.o: tclAppInit.c
cgic.o:       cgic.c cgic.h
grep.o:       grep.c
tcl-parse.o:  tcl-parse.c

lib-tcl:       $(LIB_TCL)
lib-memchan:   $(LIB_MEMCHAN)
lib-gdbm:      $(LIB_GDBM)
lib-tclgdbm:   $(LIB_TCLGDBM)
lib-md5:       $(LIB_TCLMD5)
lib-passwd:    $(LIB_TCLPASSWD)
lib-gdft:      $(LIB_TCLGDFT)
lib-mysql:     $(LIB_MYSQLTCL)

$(LIB_TCL):     FORCE
	@echo "******** making $(LIB_TCL)"
	cd $(TCLDIR)/unix; make $(PASSED_DEBUG_FLAG)

$(LIB_MEMCHAN): FORCE
	@echo "******** making $(LIB_MEMCHAN)"
	cd $(MEMCHANDIR);  make $(PASSED_DEBUG_FLAG)

$(LIB_GDBM): FORCE
	@echo "******** making $(LIB_GDBM)"
	cd $(GDBMDIR);     make $(PASSED_DEBUG_FLAG)

$(LIB_TCLGDBM): FORCE
	@echo "******** making $(LIB_TCLGDBM)"
	cd $(TCLGDBMDIR);  make INCLUDES="-I$(TCLDIR)/generic -I$(GDBMDIR)" tclgdbm.o

$(LIB_TCLMD5): FORCE
	@echo "******** making $(LIB_TCLMD5)"
	cd $(MD5DIR);      make $(MD5_PASSED_DEBUG_FLAG)

$(LIB_TCLPASSWD): FORCE
	@echo "******** making $(LIB_TCLPASSWD)"
	cd $(PASSWDDIR);   make $(PASSWD_PASSED_DEBUG_FLAG)

$(LIB_TCLGDFT): FORCE
	@echo "******** making $(LIB_TCLGDFT)"
	cd $(GDFTDIR);     make $(GDFT_PASSED_DEBUG_FLAG)

$(LIB_MYSQLTCL): FORCE
ifeq ($(PLATFORM_USING_MYSQL),yes)
	@echo "******** making $(LIB_MYSQLTCL)"
	cd $(MYSQLTCLDIR); \
		$(GMAKE) $(MYSQLTCL_PLATFORM_SELECTOR) \
			MYSQLHOME=$(MYSQLHOME) \
			TCLHOME=$(BASEDIR) \
			TKHOME=$(BASEDIR) \
			$(LIB_MYSQLTCL)
endif


FORCE:
