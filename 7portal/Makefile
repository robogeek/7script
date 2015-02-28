
include mk.cfg

all install clean:
	for dir in src main admin site; do \
		( cd $$dir; make $@; ) \
	done
