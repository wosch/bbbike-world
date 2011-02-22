# Copyright (c) 2009-2011 Wolfram Schneider, http://bbbike.org

all: perltidy
NCPU=`../bin/ncpu`

ALL:=	$(shell file * | egrep perl | awk '{print $$1}' | perl -ne 's/://; print if !/.bak$$/' | sort)

perltidy:
	echo ${ALL} | xargs -n1 -P${NCPU} -E " " perl -I. -T -cw 
	echo ${ALL} | xargs -n2 -P${NCPU} -E " " perltidy -b

clean distclean:
	rm -f *.bak *.tdy

