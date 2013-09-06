# Copyright (c) 2009-2013 Wolfram Schneider, http://bbbike.org

all: perltidy
NCPU=`../bin/ncpu`

ALL:=	$(shell file * | egrep perl | awk '{print $$1}' | perl -ne 's/://; print if !/.(bak|tdy|ERR)$$/' | sort)

perlcheck:
	${MAKE} _perlcheck 2>/dev/null || ${MAKE} _perlcheck
_perlcheck:
	@echo ${ALL} | xargs -n1 -P${NCPU} -E " " perl -T -cw

perltidy: perlcheck
	echo ${ALL} | xargs -n2 -P${NCPU} -E " " perltidy -b

clean distclean:
	rm -f *.bak *.tdy *.ERR

help:
	@echo "make [ perltidy | clean ]"
