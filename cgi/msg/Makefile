all: perltidy

NCPU=`../../../world/bin/ncpu`
ALL=??

perlcheck:
	${MAKE} _perlcheck 2>/dev/null || ${MAKE} _perlcheck
_perlcheck:
	@echo ${ALL} | xargs -n1 -P${NCPU} -E " " perl -I. -T -cw

perltidy: perlcheck
	echo ${ALL} | xargs -n2 -P${NCPU} -E " " perltidy -b -l=400

distclean: clean

clean:
	rm -f *.bak

help:
	@echo "make [ perltidy | clean ]"
