# Copyright (c) 2009-2013 Wolfram Schneider, http://bbbike.org

all: help
NCPU=`../bin/ncpu`

ALL:=	$(shell file * | egrep -iw perl | awk '{print $$1}' | perl -ne 's/://; print if !/.(bak|tdy|ERR)$$/' | sort)

perlcheck:
	${MAKE} _perlcheck 2>/dev/null || ${MAKE} _perlcheck
_perlcheck:
	@echo ${ALL} | xargs -n1 -P${NCPU} -E " " perl -I. -cw

perltidy: perlcheck
	echo ${ALL} | xargs -n4 -P${NCPU} -E " " perltidy -b

clean distclean:
	rm -f *.bak *.tdy *.ERR

help:
	@echo "usage: make [ perltidy | clean | help ]"

