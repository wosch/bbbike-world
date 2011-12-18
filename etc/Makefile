###############################################################
# Copyright (c) 2008-2011 Wolfram Schneider, http://bbbike.org
#
# configurations files
#

MUNIN_LIGHTTPD=		lighttpd_accesses lighttpd_busyservers lighttpd_idleservers lighttpd_kbytes lighttpd_uptime	
MUNIN_PLUGINS_DIR=	/etc/munin/plugins

all: help

sync-frontend:
	cp -f /etc/varnish/default.vcl varnish.vcl
	cp -f /etc/default/varnish varnish.default
	cp -f /etc/logrotate.d/munin logrotate.munin
	cp -f /etc/lighttpd/lighttpd.conf lighttpd-frontend.conf
	cp -f /etc/lighttpd/conf-available/lighttpd-munin.conf lighttpd-munin.conf

sync-backend:
	crontab -l > crontab
	cp -f /etc/lighttpd/conf-enabled/bbbike.org.conf .
	cp -f /etc/lighttpd/lighttpd.conf .
	cp -f /etc/logrotate.d/lighttpd lighttpd.logrotate


munin-lighttpd:
	for i in ${MUNIN_LIGHTTPD}; do \
	   sudo ln -fs `pwd`/../src/munin/munin-lighttpd ${MUNIN_PLUGINS_DIR}/$$i; \
	done
	${MAKE} munin-restart

munin-xen:
	sudo ln -fs `pwd`/../src/munin/xen_multi ${MUNIN_PLUGINS_DIR}
	${MAKE} munin-restart
	@echo  "don't forget to update /etc/munin/plugin-conf.d/munin-node, see ./README"
	
munin-bbbike:
	sudo cp -f ../bin/munin-bbbike ${MUNIN_PLUGINS_DIR}
	cd ${MUNIN_PLUGINS_DIR}; sudo ln -fs munin-bbbike munin-bbbike-ajax
	cd ${MUNIN_PLUGINS_DIR}; sudo ln -fs munin-bbbike munin-bbbike-output
	cd ${MUNIN_PLUGINS_DIR}; sudo ln -fs munin-bbbike munin-bbbike-pref
	cd ${MUNIN_PLUGINS_DIR}; sudo ln -fs munin-bbbike munin-bbbike-maptype
	${MAKE} munin-restart

munin-restart:
	sudo /etc/init.d/munin-node restart

help:
	@echo "make [ sync-backend | sync-frontend ]"
	@echo "make [ munin-lighttpd | munin-xen | munin-bbbike ]"
