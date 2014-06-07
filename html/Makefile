######################################################################
#
BBBIKE_WORLD_JAVASCRIPT_FILES=\
	bbbike.js \
	extract.js \
	maps3.js

JAVASCRIPT_FILES= ${BBBIKE_WORLD_JAVASCRIPT_FILES}

bbbike-js: bbbike-js.js
bbbike-js.js: maps3.js bbbike.js jquery/jquery-1.4.2.min.js devbridge-jquery-autocomplete-1.1.2/jquery.autocomplete.js
	for i in $^ ; do \
	    ${JSMIN} < $$i; \
	done > $@.tmp
	mv -f $@.tmp $@

jsbeautifier js jsb:
	for i in ${BBBIKE_WORLD_JAVASCRIPT_FILES}; do \
	   jsbeautifier -j $$i > $@.tmp && mv -f $@.tmp $$i; \
	done

clean:
	rm -f *.bak

distclean: clean
	rm -f bbbike-js.js

help:
	@echo "make [ jsbeautifier | distclean | bbbike-js ]"

