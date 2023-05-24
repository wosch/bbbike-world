###############################################################
# Copyright (c) 2015-2021 Wolfram Schneider, https://bbbike.org
#
# poly setup
#

all: update

update update-poly:
	@if [ -e ../../../../osm/download/sub-planet/europe.osm.pbf ]; then \
	   cd ../../.. && ./world/bin/sub-planet.pl --prefix=sub-planet-daily; \
	else \
	   echo "there are no sub-planet files, cannot update config"; \
	fi
	@env PAGER=cat @git diff .

help:
	@echo "make [ update | help ]"
	@echo ""

