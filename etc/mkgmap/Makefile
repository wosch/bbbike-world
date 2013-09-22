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

legend-dir:
	mkdir -p ${TYPE2LEGEND_DIR}

legend-bbbike: legend-dir
	${TYPE2LEGEND} -o ${TYPE2LEGEND_DIR}/bbbike ../../../misc/mkgmap/typ/M000002a.TXT

legend-cyclemap: legend-dir
	${TYPE2LEGEND} -o ${TYPE2LEGEND_DIR}/cyclemap cyclemap.TXT 

legend-leisure: legend-dir
	${TYPE2LEGEND} -o ${TYPE2LEGEND_DIR}/leisure freizeit.TXT

legend: clean legend-bbbike legend-cyclemap legend-leisure legend-index

legend-index:
	ls ${TYPE2LEGEND_DIR} | egrep -v index.html | \
	  perl -ne 'chomp; print qq{<a href="$$_">$$_</a><br/>\n}' > ${TYPE2LEGEND_DIR}/index.html
	( tidy -i -m ${TYPE2LEGEND_DIR}/index.html || tidy -i -m ${TYPE2LEGEND_DIR}/index.html ) 2>/dev/null

clean:
	rm -rf ${TYPE2LEGEND_DIR}

help:
	@echo "usage: make [ targets ... ]"
	@echo ""
	@echo "  [ help | clean | legend ]"

