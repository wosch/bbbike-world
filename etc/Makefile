###############################################################
# Copyright (c) 2008-2015 Wolfram Schneider, http://bbbike.org
#
# configurations files
#

MUNIN_LIGHTTPD=	lighttpd_accesses lighttpd_busyservers lighttpd_idleservers lighttpd_kbytes lighttpd_uptime	
MUNIN_PLUGINS_DIR=	/etc/munin/plugins

CRONTAB_ROOT=/etc/cron.d/bbbike.root

all: help

sync-frontend:
	cp -f /etc/varnish/default.vcl varnish/varnish.vcl
	cp -f /etc/default/varnish varnish/varnish.default
	cp -f /etc/default/varnishncsa varnish/varnishncsa.default
	cp -f /etc/lighttpd/lighttpd.conf lighttpd/lighttpd-frontend.conf
	cp -f /etc/lighttpd/conf-available/lighttpd-munin.conf munin/lighttpd-munin.conf
	cp -f /etc/logrotate.d/munin logrotate/logrotate.munin

install-frontend-lighttpd:
	cd /etc/lighttpd/conf-available; \
	  sudo ln -fs /usr/local/www/bbbike/world/etc/lighttpd/munin-fastcgi.conf;
	cd /etc/lighttpd/conf-enabled; \
	  sudo ln -fs ../conf-available/munin-fastcgi.conf
	sudo /etc/init.d/lighttpd restart

sync-backend:
	crontab -l > crontab
	cp -f /etc/lighttpd/conf-enabled/bbbike.org.conf lighttpd
	cp -f /etc/lighttpd/lighttpd.conf lighttpd
	cp -f /etc/logrotate.d/lighttpd logrotate/lighttpd.logrotate

install-backend-lighttpd:
	sudo cp -f logrotate/lighttpd.logrotate /etc/logrotate.d/lighttpd 
	sudo cp -f lighttpd/bbbike.org.conf /etc/lighttpd/conf-available
	sudo cp -f lighttpd/lighttpd.conf /etc/lighttpd/lighttpd.conf 
	cd /etc/lighttpd/conf-enabled; sudo ln -fs ../conf-available/bbbike.org.conf
	sudo /etc/init.d/lighttpd restart

install-munin-lighttpd:
	for i in ${MUNIN_LIGHTTPD}; do \
	   sudo ln -fs `pwd`/../src/munin/munin-lighttpd ${MUNIN_PLUGINS_DIR}/$$i; \
	done
	${MAKE} munin-restart

crontab-root:
	if [ ! -e ${CRONTAB_ROOT} ]; then \
	   sudo ln -fs `pwd`/crontab.root ${CRONTAB_ROOT}; \
	fi

perltidy perlcheck:
	${MAKE} -C./munin $@

clean distclean:
	rm -f *.bak *.tdy *.ERR

help:
	@echo "make [ sync-backend | sync-frontend ]"
	@echo "     [ install-backend-lighttpd ]"
	@echo "     [ install-frontend-lighttpd ]"
	@echo "     [ install-munin-lighttpd ]"
	@echo "     [ crontab-root ]"
	@echo "     [ clean ]"
	@echo ""
	@echo "for bbbike.de: "
	@echo "make MUNIN_BBBIKE=\"bbbike-output bbbike-pref bbbike-route bbbike-appid\" install-munin-bbbike"

