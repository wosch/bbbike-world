######################################################################
#
BBBIKE_WORLD_JAVASCRIPT_FILES=	slippymap.js

JAVASCRIPT_FILES= ${BBBIKE_WORLD_JAVASCRIPT_FILES}

jsbeautifier js jsb:
	for i in ${BBBIKE_WORLD_JAVASCRIPT_FILES}; do \
	   jsbeautifier -j $$i > $@.tmp && mv -f $@.tmp $$i; \
	done

clean:
	rm -f *.bak
distclean: clean

help:
	@echo "make [ jsbeautifier | clean ]"

