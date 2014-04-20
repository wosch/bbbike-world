# Copyright (c) Mar 2010-2014, http://BBBike.org
#
# create an atom based RSS feed for BBBike @ World

FEED_SCRIPT=	./feed.pl
RSS=		bbbike-world.xml

all: ${RSS}

bbbike-world.xml: ${FEED_SCRIPT}
	${FEED_SCRIPT} | tidy -w 140 -xml -i -ascii > $@.tmp 2> $@.log
	mv -f $@.tmp $@
	rm -f $@.log

perlcheck:
	${MAKE} _perlcheck 2>/dev/null || ${MAKE} _perlcheck
_perlcheck:
	@perl -cw ${FEED_SCRIPT}

perltidy: perlcheck
	perltidy -b ${FEED_SCRIPT}

clean:
	rm -f *.log *.bak *.tdy *.ERR

distclean: clean
	rm -f ${RSS}

help:
	@echo "make [ clean | all | perltidy ]"

