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

sync-backend:
	crontab -l > crontab
	cp -f /etc/lighttpd/conf-enabled/bbbike.org.conf .
	cp -f /etc/lighttpd/lighttpd.conf .
	cp -f /etc/logrotate.d/lighttpd lighttpd.logrotate


munin-lighttpd:
	for i in ${MUNIN_LIGHTTPD}; do \
	   sudo ln -fs `pwd`/../bin/munin-lighttpd ${MUNIN_PLUGINS_DIR}/$$i; \
	done
	
help:
	@echo "make [ sync-backend | sync-frontend | munin-lighttpd ]"
