###############################################################
# Copyright (c) 2015-2024 Wolfram Schneider, https://bbbike.org
#
# poly setup for daily planet
#

all: update

update update-poly:
	@if [ -e ../../../../osm/download/sub-planet-daily/europe.osm.pbf ]; then \
	   cd ../../.. && ./world/bin/sub-planet.pl --prefix=sub-planet-daily; \
	else \
	   echo "there are no sub-planet-daily files, cannot update config"; \
	fi
	@env PAGER=cat git diff .

help:
	@echo "make update"

