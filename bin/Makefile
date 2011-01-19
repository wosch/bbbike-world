# Copyright (c) 2009-2011 Wolfram Schneider, http://bbbike.org

all: perltidy

ALL=	`file * | egrep perl | awk '{print $$1}' | perl -ne 's/://; print if !/.bak$$/' | sort`

perltidy:
	perltidy -b ${ALL}

clean distclean:
	rm -f *.bak *.tdy

