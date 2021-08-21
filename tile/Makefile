###############################################################
# Copyright (c) 2008-2021 Wolfram Schneider, https://bbbike.org
#
# Get and convert OpenStreetMap.org data to BBBike
#
# For more information about BBBike, visit https://www.bbbike.org
#

# need older versions for libapache2-mod-tile 
POSTGRES_VERSION=	9.3
APACHE2_VERSION=	2.4.7-1ubuntu4.22
APACHE2_MODULES=	apache2=${APACHE2_VERSION} apache2-bin=${APACHE2_VERSION} apache2-data=${APACHE2_VERSION} apache2-mpm-event=${APACHE2_VERSION} 


DEBIAN_MODULES_SYTEM= 	unzip bzip2 make subversion tidy gcc git munin-node time

#LEGACY_MODULES= 	libmapnik2.2 libgdal1h libgeos-c1 gdal-bin=1.10.1+dfsg-5ubuntu1 python-mapnik=2.2.0+ds1-6build2 postgis=2.1.2+dfsg-2ubuntu0.1

DEBIAN_MODULES= 	libimager-perl imagemagick libinline-perl libhtml-tagcloud-perl \
        		libtie-ixhash-perl libhtml-parser-perl libwww-perl

TILE_MODULES= 	postgresql-${POSTGRES_VERSION}  postgresql-client-${POSTGRES_VERSION} postgresql-contrib-${POSTGRES_VERSION} osm2pgsql=0.88.1-1 \
		python-mapnik=2.2.0+ds1-6build2 postgresql-9.3-postgis-2.1=2.1.2+dfsg-2ubuntu0.2

TILE_MODULES_OSM= renderd libapache2-mod-tile=0.4-27~trusty1 openstreetmap-postgis-db-setup


PROJECT_DIR=	$$HOME/projects
DEBIAN_INSTALL_FLAGS=	-y  # -y -d

all: help

install-packages-system: perl
	sudo apt-get install ${DEBIAN_INSTALL_FLAGS} ${DEBIAN_MODULES_SYTEM} ${APACHE2_MODULES}	
install-packages: 
	sudo apt-get install ${DEBIAN_INSTALL_FLAGS} ${DEBIAN_MODULES} 
	sudo apt-get install ${DEBIAN_INSTALL_FLAGS} ${TILE_MODULES}
	sudo apt-get install ${DEBIAN_INSTALL_FLAGS} ${TILE_MODULES_OSM}

perl:
	if [ ! -e /usr/local/bin/perl ]; then \
	   sudo ln -sf /usr/bin/perl /usr/local/bin/perl; \
	fi

osm-repo:
	if [ ! -e /etc/apt/sources.list.d/openstreetmap.list ]; then \
	   sudo cp ${PROJECT_DIR}/bbbike/world/etc/apt/ubuntu/trusty/sources.list.d/openstreetmap.list /etc/apt/sources.list.d/openstreetmap.list ;\
	   sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys AE74800FB745A04C; \
	fi
	if [ ! -e /etc/apt/sources.list.d/tile-legacy.list ]; then \
	   sudo cp ${PROJECT_DIR}/bbbike/world/etc/apt/ubuntu/trusty-legacy/sources.list.d/tile-legacy.list /etc/apt/sources.list.d/tile-legacy.list ;\
	fi
	sudo apt-get -qq update

nodejs-repo:
	if [ ! -e /etc/apt/sources.list.d/nodejs.list ]; then \
	   sudo cp ${PROJECT_DIR}/bbbike/world/etc/apt/ubuntu/trusty/sources.list.d/nodejs.list /etc/apt/sources.list.d/nodejs.list ;\
	   curl -sSf https://deb.nodesource.com/gpgkey/nodesource.gpg.key | sudo apt-key add -; \
	fi
	sudo apt-get -qq update

# in case of trouble run:
# sudo dpkg-reconfigure openstreetmap-postgis-db-setup
postgis-utf8:
	-sudo /etc/init.d/renderd stop
	sudo pg_dropcluster --stop ${POSTGRES_VERSION} main
	sudo pg_createcluster --start -e UTF-8 ${POSTGRES_VERSION} main

openstreetmap-postgis: postgis-utf8
	sudo apt-get purge -y openstreetmap-postgis-db-setup </dev/null
	sudo apt-get install -y openstreetmap-postgis-db-setup </dev/null

repo-checkout: git-checkout
	
git-checkout:
	mkdir -p ${PROJECT_DIR}
	cd ${PROJECT_DIR}; if [ ! -e mc ]; then git clone --depth=1 ssh://git.bbbike.org/home/wosch/git/mc; fi
	cd ${PROJECT_DIR}; if [ ! -e mapnik-bbbike ]; then git clone --depth=1 https://github.com/eserte/mapnik-bbbike; fi
	cd ${PROJECT_DIR}; \
	  if [ ! -e bbbike-eserte ]; then \
	    git clone --depth=1 git://github.com/eserte/bbbike.git bbbike-eserte; \
	  fi

etc-symlinks:
	cd /etc; \
	sudo ln -sf ~/projects/mapnik-bbbike . ;\
	sudo ln -fs ~/projects/bbbike/world/tile/etc/renderd22.conf .;\
	sudo ln -fs renderd22.conf renderd.conf

etc-init-symlinks:
	cd /etc/init.d/; sudo ln -fs ~/projects/bbbike/world/tile/etc/renderd-slowstart .;
	sudo update-rc.d renderd-slowstart  defaults 30
	-sudo update-rc.d renderd disable

apache-symlinks:
	cd /etc/apache2/sites-available; \
	  sudo ln -sf ~/projects/bbbike/world/etc/apache2/tile.conf .
	sudo a2ensite tile.conf
	sudo a2enmod tile
	sudo rm -f /etc/apache2/sites-enabled/tileserver_site 
	sudo /etc/init.d/renderd restart
	sudo /etc/init.d/apache2 restart

mapnik-symlinks:
	cd ~/projects/mapnik-bbbike; \
	  make -C./tools setup-mapnik-on-mosor

www-symlinks:
	cd /var/www; \
	  sudo ln -fs ~/projects/mc/www mc; \
	  sudo ln -fs ~/projects/bbbike/world/tile/web/robots.txt .; \
	  sudo ln -fs ~/projects/bbbike/world/web/test.txt .; \
	  sudo ln -fs ~/projects/bbbike/images/favicon.ico ; \
	  sudo ln -fs ~/projects/bbbike/world/tile/web/index.html 
	cd /var/www/osm; \
	  sudo ln -fs ~/projects/bbbike/html/OpenLayers; \
	  sudo ln -fs ~/projects/bbbike/world/tile/web/style.css; \
	  sudo ln -fs ~/projects/bbbike/world/tile/web/slippymap.js; \
	  sudo ln -fs ~/projects/bbbike/world/tile/web/slippymap-dev.js; \
	  sudo ln -fs ~/projects/bbbike/world/tile/web/slippymap-dev.html; \
	  sudo ln -fs ~/projects/bbbike/world/tile/web/slippymap.html; \
	  sudo ln -fs ~/projects/bbbike/world/tile/web/slippymap.html index.html

symlinks: etc-symlinks etc-init-symlinks apache-symlinks mapnik-symlinks www-symlinks 
	
bbbike-mapnik:
	cd ${PROJECT_DIR}/bbbike; \
	  sudo make bbbike-mapnik-config; \
	  make bbbike2wgs84-mapnik; \
	  make bbbike-mapnik-postgis 

mapnik-restart:
	make -C ${PROJECT_DIR}/bbbike $@

munin:
	sudo apt-get install -y libdbd-pg-perl
	cd /etc/munin/plugins/; \
	  sudo ln -fs /usr/share/munin/plugins/postgres_* .; \
	  for i in postgres_*_;do echo $$i;sudo mv $$i $${i}ALL;done
	sudo /etc/init.d/munin-node stop
	sleep 1
	sudo /etc/init.d/munin-node start

manual:
	@echo ""
	@echo "now run:"
	@echo "make openstreetmap-postgis bbbike-mapnik mapnik-restart"
	@echo ""

install-all: osm-repo nodejs-repo install-packages-system repo-checkout install-packages symlinks munin manual

distclean: clean
	sudo rm -f /etc/mapnik-bbbike
	sudo rm -f /etc/renderd22.conf /etc/renderd.conf

clean:

apt-distclean apt-purge: 
	sudo apt-get purge -y ${DEBIAN_INSTALL_FLAGS} ${APACHE2_MODULES} ${LEGACY_MODULES} ${DEBIAN_MODULES} ${TILE_MODULES} ${TILE_MODULES_OSM}
	sudo apt-get purge -y libpq5* apache2* postgis* postgresql* 
	sudo apt-get autoremove -y
	make apt-distclean-carto

apt-distclean-carto:
	# strange bug in dpkg, which follows symlinks on delete
	if ! test -e etc/renderd22.conf; then git checkout etc/renderd22.conf; fi

help:
	@echo ""
	@echo "usage: make [ targets ... ]"
	@echo ""
	@echo "  [ install-all ]"
	@echo "  [ osm-repo | nodejs-repo ]"
	@echo "  [ install-packages | symlinks | bbbike-mapnik ]"
	@echo "  [ openstreetmap-postgis | mapnik-restart ]"
	@echo "  [ clean | distclean | apt-distclean ]"
	@echo ""
	@echo "see also ./world/tile/README.tile"

# sudo update-rc.d lighttpd disable

