###############################################################
# Copyright (c) 2008-2014 Wolfram Schneider, http://bbbike.org
#
# Get and convert OpenStreetMap.org data to BBBike
#
# For more information about BBBike, visit http://www.bbbike.org
#

DEBIAN_RELEASE=wheezy

DEBIAN_MODULES= unzip bzip2 make subversion tidy gcc git \
        libimager-perl imagemagick libinline-perl libhtml-tagcloud-perl \
        libtie-ixhash-perl libhtml-parser-perl apache2

TILE_MODULES= python-mapnik2 postgresql #osm2pgsql=0.80.0+r27899-4
TILE_MODULES_OSM= openstreetmap-mapnik-stylesheet-data  postgresql-contrib postgresql-contrib-9.1 renderd
#libapache2-mod-tile openstreetmap-mapnik-stylesheet-data


PROJECT_DIR=	$$HOME/projects
DEBIAN_INSTALL_FLAGS=	-y  # -y -d

all: help

install-packages: perl
	sudo apt-get install ${DEBIAN_INSTALL_FLAGS} ${DEBIAN_MODULES}	
	sudo apt-get install ${DEBIAN_INSTALL_FLAGS} ${TILE_MODULES}	

perl:
	if [ ! -e /usr/local/bin/perl ]; then \
	   sudo ln -sf /usr/bin/perl /usr/local/bin/perl; \
	fi

osm-repo:
	if [ ! -e /etc/apt/sources.list.d/openstreetmap.list ]; then \
	   sudo cp ${PROJECT_DIR}/bbbike/world/etc/apt/wheezy/sources.list.d/openstreetmap.list /etc/apt/sources.list.d/openstreetmap.list ;\
	   sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys AE74800FB745A04C; \
	fi
	sudo apt-get update
	sudo apt-get install ${DEBIAN_INSTALL_FLAGS} ${TILE_MODULES_OSM}	

postgis-utf8:
	-sudo /etc/init.d/renderd stop
	sudo pg_dropcluster --stop 9.1 main
	sudo pg_createcluster --start -e UTF-8 9.1 main

openstreetmap-postgis: postgis-utf8
	sudo apt-get purge -y openstreetmap-postgis-db-setup </dev/null
	sudo apt-get install -y openstreetmap-postgis-db-setup </dev/null

repo-checkout: git-checkout svn-checkout
	
git-checkout:
	mkdir -p ${PROJECT_DIR}
	cd ${PROJECT_DIR}; if [ ! -e mc ]; then git clone ssh://git.bbbike.org/home/wosch/git/mc; fi
	cd ${PROJECT_DIR}; if [ ! -e mapnik-bbbike ]; then git clone https://github.com/eserte/mapnik-bbbike; fi
	cd ${PROJECT_DIR}; \
	  if [ ! -e bbbike-eserte ]; then \
	    git clone bbbike bbbike-eserte; \
	    git remote add eserte git://github.com/eserte/bbbike.git; \
	    git fetch eserte; \
	    git checkout -b eserte_master eserte/master; \
	  fi

svn-checkout:
	mkdir -p ${PROJECT_DIR}
	cd ${PROJECT_DIR}; if [ ! -e mapnik ]; then svn checkout http://svn.openstreetmap.org/applications/rendering/mapnik; fi
	cd ${PROJECT_DIR}; if [ ! -e mapnik-german ]; then svn checkout http://svn.openstreetmap.org/applications/rendering/mapnik-german; fi

etc-symlinks:
	cd /etc; \
	sudo ln -sf ${PROJECT_DIR}/mapnik-german . ;\
	sudo ln -sf ~/projects/mapnik-bbbike . ;\
	sudo ln -fs ~/projects/bbbike/world/tile/etc/renderd20.conf .;\
	sudo ln -fs renderd20.conf renderd.conf

etc-init-symlinks:
	cd /etc/init.d/; sudo ln -fs ~/projects/bbbike/world/tile/etc/renderd-slowstart .;
	sudo update-rc.d renderd-slowstart  defaults 30
	-sudo update-rc.d renderd disable

apache-symlinks:
	cd /etc/apache2/sites-available; \
	  sudo ln -sf ~/projects/bbbike/world/tile/etc/apache2-tile.conf .
	sudo a2ensite apache2-tile.conf
	sudo a2enmod tile
	sudo rm -f /etc/apache2/sites-enabled/tileserver_site 
	sudo /etc/init.d/renderd restart
	sudo /etc/init.d/apache2 restart

mapnik-symlinks:
	cd ~/projects/mapnik-bbbike; \
	  make -C./tools setup-mapnik-on-mosor

www-symlinks:
	cd /var/www; \
	  sudo ln -fs ~/projects/mc .;\
	  sudo ln -fs ~/projects/bbbike/world/tile/web/robots.txt .; \
	  sudo ln -fs ~/projects/bbbike/images/favicon.ico ; \
	  sudo ln -fs ~/projects/bbbike/world/tile/web/index.html 
	cd /var/www/osm; \
	  sudo ln -fs ~/projects/bbbike/html/OpenLayers; \
	  sudo ln -fs ~/projects/bbbike/world/tile/web/style.css; \
	  sudo ln -fs ~/projects/bbbike/world/tile/web/slippymap.js; \
	  sudo ln -fs ~/projects/bbbike/world/tile/web/slippymap-dev.html; \
	  sudo ln -fs ~/projects/bbbike/world/tile/web/slippymap.html index.html

symlinks: etc-symlinks etc-init-symlinks apache-symlinks mapnik-symlinks www-symlinks
	
bbbike-mapnik:
	cd ${PROJECT_DIR}/bbbike; \
	  sudo make bbbike-mapnik-config; \
	  make bbbike2wgs84-mapnik; \
	  make bbbike-mapnik-postgis 

mod-tile:
	sudo apt-get install ${DEBIAN_INSTALL_FLAGS} libapache2-mod-tile

mapnik-restart:
	make -C ${PROJECT_DIR}/bbbike $@

manual:
	@echo ""
	@echo "now run"
	@echo "make openstreetmap-postgis bbbike-mapnik mapnik-restart"
	@echo ""

install-all: install-packages osm-repo postgis-utf8 repo-checkout symlinks manual

distclean: clean
clean:

help:
	@echo ""
	@echo "usage: make [ targets ... ]"
	@echo ""
	@echo "  [ install-all ]"
	@echo "  [ install-packages | symlinks | bbbike-mapnik ]"
	@echo "  [ openstreetmap-postgis | mapnik-restart ]"
	@echo "  [ clean | distclean ]"
	@echo ""
	@echo "see also ./world/tile/README.tile"

