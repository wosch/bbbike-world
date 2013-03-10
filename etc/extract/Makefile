######################################################################
#
BBBIKE_WORLD_JAVASCRIPT_FILES=msg.de.json msg.en.json

JAVASCRIPT_FILES= ${BBBIKE_WORLD_JAVASCRIPT_FILES}

jsbeautifier js:
	for i in ${BBBIKE_WORLD_JAVASCRIPT_FILES}; do \
	   jsbeautifier -k $$i > $@.tmp && mv -f $@.tmp $$i; \
	done

clean:
	rm -f *.bak
distclean: clean

help:
	@echo "make [ jsbeautifier | clean ]"

