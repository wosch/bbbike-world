###############################################################
# Copyright (c) 2015 Wolfram Schneider, https://bbbike.org
#
# poly setup
#

all: update

update update-poly:
	@if [ -e ../../../../osm/download/sub-planet/europe.osm.pbf ]; then \
	   cd ../../.. && ./world/bin/sub-planet.pl; \
	else \
	   echo "there are no sub-planet files, cannot update config"; \
	fi
	@git diff .

help:
	@echo "make [ update | help ]"
	@echo ""

