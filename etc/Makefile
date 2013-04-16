###############################################################
# Copyright (c) 2008-2013 Wolfram Schneider, http://bbbike.org
#
# configurations files
#

MUNIN_LIGHTTPD=	lighttpd_accesses lighttpd_busyservers lighttpd_idleservers lighttpd_kbytes lighttpd_uptime	
MUNIN_BBBIKE= 	bbbike-ajax bbbike-output bbbike-pref bbbike-maptype bbbike-route bbbike-appid
MUNIN_PLUGINS_DIR=	/etc/munin/plugins

all: help

sync-frontend:
	cp -f /etc/varnish/default.vcl varnish/varnish.vcl
	cp -f /etc/default/varnish varnish/varnish.default
	cp -f /etc/default/varnishncsa varnish/varnishncsa.default
	cp -f /etc/lighttpd/lighttpd.conf lighttpd/lighttpd-frontend.conf
	cp -f /etc/lighttpd/conf-available/lighttpd-munin.conf munin/lighttpd-munin.conf
	cp -f /etc/logrotate.d/munin logrotate/logrotate.munin

sync-backend:
	crontab -l > crontab
	cp -f /etc/lighttpd/conf-enabled/bbbike.org.conf lighttpd
	cp -f /etc/lighttpd/lighttpd.conf lighttpd
	cp -f /etc/logrotate.d/lighttpd logrotate/lighttpd.logrotate


install-munin-lighttpd:
	for i in ${MUNIN_LIGHTTPD}; do \
	   sudo ln -fs `pwd`/../src/munin/munin-lighttpd ${MUNIN_PLUGINS_DIR}/$$i; \
	done
	${MAKE} munin-restart

install-munin-xen:
	sudo ln -fs `pwd`/../src/munin/xen_multi ${MUNIN_PLUGINS_DIR}
	${MAKE} munin-restart
	@echo  "don't forget to update /etc/munin/plugin-conf.d/munin-node, see ./README"
	
install-munin-bbbike:
	for i in ${MUNIN_BBBIKE}; do \
	   sudo ln -fs `pwd`/../bin/munin-bbbike ${MUNIN_PLUGINS_DIR}/$$i; \
	done
	${MAKE} munin-restart

install-munin-bbbike-extract:
	sudo ln -fs `pwd`/../bin/munin-bbbike-extract ${MUNIN_PLUGINS_DIR}/bbbike-extract; \
	sudo ln -fs `pwd`/../bin/munin-bbbike-extract ${MUNIN_PLUGINS_DIR}/bbbike-extract-tilesize; \
	sudo ln -fs `pwd`/../bin/munin-bbbike-extract-jobs ${MUNIN_PLUGINS_DIR}/bbbike-extract-jobs; \
	${MAKE} munin-restart

munin-restart:
	sudo /etc/init.d/munin-node restart

help:
	@echo "make [ sync-backend | sync-frontend ]"
	@echo "make [ install-munin-lighttpd ]"
	@echo "make [ install-munin-bbbike | install-munin-bbbike-extract ]"
	@echo "make [ install-munin-xen ]"
	@echo ""
	@echo "for bbbike.de: "
	@echo "make MUNIN_BBBIKE=\"bbbike-output bbbike-pref bbbike-route bbbike-appid\" install-munin-bbbike"

