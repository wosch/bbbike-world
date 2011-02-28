# Copyright (c) Mar 2010, bbbike.org
# create an atom based RSS feed for BBBike @ World

FEED_SCRIPT=	./feed.pl
RSS=		bbbike-world.xml

all: ${RSS}

bbbike-world.xml: ${FEED_SCRIPT} perltidy
	${FEED_SCRIPT} | tidy -xml -i > $@ 2> $@.log

perltidy:
	perl -cw ${FEED_SCRIPT} 2>/dev/null || perl -cw ${FEED_SCRIPT}
	perltidy -b ${FEED_SCRIPT}

clean:
	rm -f *.log *.bak *.tdy

distclean: clean
	rm -f ${RSS}

help:
	@echo "make [ clean | all | perltidy ]"

