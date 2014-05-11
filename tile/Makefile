###############################################################
# Copyright (c) 2008-2014 Wolfram Schneider, http://bbbike.org
#
# Get and convert OpenStreetMap.org data to BBBike
#
# For more information about BBBike, visit http://www.bbbike.org
#

DEBIAN_MODULES= unzip bzip2 make subversion tidy gcc git \
        libimager-perl imagemagick libinline-perl libhtml-tagcloud-perl \
        libtie-ixhash-perl libhtml-parser-perl

TILE_MODULES= python-mapnik2 postgresql osm2pgsql

PROJECT_DIR=	$$HOME/projects
DEBIAN_INSTALL_FLAGS=	-y -d

install-packages: perl
	sudo apt-get install ${DEBIAN_INSTALL_FLAGS} ${DEBIAN_MODULES}	
	sudo apt-get install ${DEBIAN_INSTALL_FLAGS} ${TILE_MODULES}	

perl:
	if [ ! -e /usr/local/bin/perl ]; then \
	   sudo ln -sf /usr/bin/perl /usr/local/bin/perl; \
	fi

repo-checkout: git-checkout svn-checkout
	
git-checkout:
	mkdir -p ${PROJECT_DIR}
	cd ${PROJECT_DIR}; if [ ! -e mc ]; then git clone ssh://git.bbbike.org/home/wosch/git/mc; fi
	cd ${PROJECT_DIR}; if [ ! -e mapnik-bbbike ]; then git clone https://github.com/eserte/mapnik-bbbike; fi
	cd ${PROJECT_DIR}; if [ ! -e bbbike-eserte ]; then git clone git://github.com/eserte/bbbike.git bbbike-eserte; fi

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
	sudo update-rc.d renderd disable

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

symlinks: etc-symlinks etc-init-symlinks apache-symlinks mapnik-symlinks www-symlinks
	
bbbike-mapnik:
	cd ${PROJECT_DIR}/bbbike; \
	  sudo make bbbike-mapnik-config; \
	  make bbbike2wgs84-mapnik; \
	  make bbbike-mapnik-postgis 

all: install-packages repo-checkout symlinks

distclean: clean
clean:

help:
	@echo ""
	@echo "usage: make [ targets ... ]"
	@echo ""
	@echo "  [ install-packages | symlinks | bbbike-mapnik ]"
	@echo "  [ clean | distclean ]"
	@echo ""
	@echo "see also ./world/tile/README.tile"

