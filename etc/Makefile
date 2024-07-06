###############################################################
# Copyright (c) 2008-2017 Wolfram Schneider, https://bbbike.org
#
# configurations files
#

MUNIN_PLUGINS_DIR=	/etc/munin/plugins

CRONTAB_ROOT=/etc/cron.d/bbbike

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
	  sudo ln -fs /usr/local/www/bbbike.org/world/etc/lighttpd/munin-fastcgi.conf;
	cd /etc/lighttpd/conf-available; \
	  sudo ln -fs /usr/local/www/bbbike.org/world/etc/lighttpd/lighttpd-frontend.conf
	cd /etc/lighttpd/conf-enabled; \
	  sudo ln -fs ../conf-available/munin-fastcgi.conf
	cd /etc/lighttpd; \
	  if [ -f lighttpd.conf -a ! -h lighttpd.conf ]; then \
	    sudo mv -f lighttpd.conf lighttpd.conf.original; \
	  fi; \
	  sudo ln -fs conf-available/lighttpd-frontend.conf lighttpd.conf
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

crontab-root:
	if [ ! -e ${CRONTAB_ROOT} ]; then \
	   sudo cp cron.d/bbbike ${CRONTAB_ROOT}; \
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

