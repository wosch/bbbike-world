###############################################################
# Copyright (c) 2008-2024 Wolfram Schneider, https://bbbike.org
#
# configurations files
#

CRONTAB_ROOT=/etc/cron.d/bbbike

all: help

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

clean distclean:
	rm -f *.bak *.tdy *.ERR

help:
	@echo "make [ sync-backend ]"
	@echo "     [ install-backend-lighttpd ]"
	@echo "     [ crontab-root ]"
	@echo "     [ clean ]"

