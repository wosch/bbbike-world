###############################################################
# Copyright (c) 2013 Wolfram Schneider, http://bbbike.org
#
# Get and convert OpenStreetMap.org data to BBBike
#
# For more information about BBBike, visit http://www.bbbike.org
#
# see also
# http://wiki.openstreetmap.org/wiki/Osmconvert#Download
#

PROG=osmconvert
DATE := $(shell date '+%Y-%m-%d')

all: ${PROG}

${PROG}: ${PROG}.c
	cc -x c $< -lz -O3 -o ${PROG}-${DATE}

help:
	@echo "usage: make [ targets ... ]"
	@echo ""
	@echo "  [ help | clean | all ]"

clean:
	rm -f ${PROG} ${PROG}-${DATE}

