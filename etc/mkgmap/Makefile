###############################################################
# Copyright (c) 2008-2013 Wolfram Schneider, http://bbbike.org
#
# Get and convert OpenStreetMap.org data to BBBike
#
# For more information about BBBike, visit http://www.bbbike.org
#

MAX_CPU=	`../../bin/ncpu`
XARGS=		${NICE} `which gxargs xargs | head -1`
TIME=		time
TYPE2LEGEND=	../../../miscsrc/typ2legend.pl
TYPE2LEGEND_DIR=	../../web/garmin

all: help

legend:
	mkdir -p ${TYPE2LEGEND_DIR}

legend-bbbike:
	${TYPE2LEGEND} -o ${TYPE2LEGEND_DIR}/bbbike ../../../misc/mkgmap/typ/M000002a.TXT

legend-cyclemap:
	${TYPE2LEGEND} -o ${TYPE2LEGEND_DIR}/cyclemap cyclemap.TXT 

legend-leisure:
	${TYPE2LEGEND} -o ${TYPE2LEGEND_DIR}/leisure freizeit.TXT

clean:
	rm -rf ${TYPE2LEGEND_DIR}

help:
	@echo "usage: make [ targets ... ]"
	@echo ""
	@echo "  [ help | clean | legend ]"

