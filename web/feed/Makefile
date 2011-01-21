# Copyright (c) Mar 2010, bbbike.org
# create an atom based RSS feed for BBBike @ World

FEED_SCRIPT=	./feed.pl
RSS=		bbbike-world.xml

all: ${RSS}

bbbike-world.xml: ${FEED_SCRIPT}
	${FEED_SCRIPT} | tidy -xml -i > $@ 2> $@.log

clean:
	rm -f *.log

distclean: clean
	rm -f ${RSS}

