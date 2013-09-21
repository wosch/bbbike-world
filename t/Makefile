# Copyright (c) 2009-2013 Wolfram Schneider, http://bbbike.org

all: help

NCPU:=  $(shell ../bin/ncpu)

perlcheck:
	${MAKE} _perlcheck >/dev/null 2>&1 || ${MAKE} _perlcheck
_perlcheck:
	cd ../../; ls world/t/*.t | xargs -n1 -P${NCPU} perl -I. -cw

perltidy: perlcheck
	cd ../../; ls world/t/*.t | xargs -n4 -P${NCPU} perltidy -b

clean distclean:
	rm -f *.bak *.tdy *.ERR

help:
	@echo "usage: make [ perltidy | clean | help ]"

