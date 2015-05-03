###############################################################
# Copyright (c) 2015 Wolfram Schneider, http://bbbike.org
#
# poly setup
#

all: update

update update-poly:
	cd ../../.. && ./world/bin/sub-planet.pl 
	@git diff .
	@echo "Now run: "
	@echo "  nice -15 ionice -c 2 -n 6 time xargs -n1 -P2 -0 /bin/sh -c < world/etc/sub-planet/sub-planet.sh"

help:
	@echo "make [ update | help ]"
	@echo ""

