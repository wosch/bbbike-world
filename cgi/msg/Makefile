all: perltidy

NCPU=`../../world/bin/ncpu`
ALL=??

perlcheck:
	@echo ${ALL} | xargs -n1 -P${NCPU} -E " " perl -I. -T -cw 2>/dev/null

perltidy: perlcheck
	echo ${ALL} | xargs -n2 -P${NCPU} -E " " perltidy -b -l=400

distclean: clean

clean:
	rm -f *.bak

help:
	@echo "make [ perltidy | clean ]"
