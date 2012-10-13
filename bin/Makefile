# Copyright (c) 2009-2012 Wolfram Schneider, http://bbbike.org

all: help
NCPU=`../bin/ncpu`

ALL:=	$(shell file * | egrep perl | awk '{print $$1}' | perl -ne 's/://; print if !/.bak$$/' | sort)

perlcheck:
	@echo ${ALL} | xargs -n1 -P${NCPU} -E " " perl -I. -cw 2>/dev/null

perltidy: perlcheck
	echo ${ALL} | xargs -n2 -P${NCPU} -E " " perltidy -b

clean distclean:
	rm -f *.bak *.tdy

help:
	@echo "usage: make [ perltidy | clean | help ]"

