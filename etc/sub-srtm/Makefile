###############################################################
# Copyright (c) 2015 Wolfram Schneider, https://bbbike.org
#
# poly setup
#

all: update

update update-poly:
	cd ../../.. && ./world/bin/sub-planet.pl --prefix=sub-srtm
	@git diff .

help:
	@echo "make [ update | help ]"
	@echo ""

