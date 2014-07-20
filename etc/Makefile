###############################################################
# Copyright (c) 2008-2014 Wolfram Schneider, http://bbbike.org
#
# configurations files
#

MUNIN_LIGHTTPD=	lighttpd_accesses lighttpd_busyservers lighttpd_idleservers lighttpd_kbytes lighttpd_uptime	
MUNIN_BBBIKE= 	bbbike-ajax bbbike-output bbbike-pref bbbike-maptype bbbike-route bbbike-appid
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
	sudo ln -fs `pwd`/../bin/munin-bbbike-extract ${MUNIN_PLUGINS_DIR}/bbbike-extract-format; \
	sudo ln -fs `pwd`/../bin/munin-bbbike-extract-jobs ${MUNIN_PLUGINS_DIR}/bbbike-extract-jobs; \
	sudo ln -fs `pwd`/../bin/munin-bbbike-extract-diskusage ${MUNIN_PLUGINS_DIR}/bbbike-extract-diskusage; \
	sudo ln -fs `pwd`/../bin/munin-bbbike-extract-files ${MUNIN_PLUGINS_DIR}/bbbike-extract-files; \
	${MAKE} munin-restart

munin-restart:
	sudo /etc/init.d/munin-node stop
	sleep 0.2
	sudo /etc/init.d/munin-node start

crontab-root:
	if [ ! -e ${CRONTAB_ROOT} ]; then \
	   sudo ln -fs `pwd`/crontab.root ${CRONTAB_ROOT}; \
	fi

##################################################################################
# perltidy section
#
NCPU=`../bin/ncpu`
PERL_FILES:=	$(shell file * | egrep -iw perl | egrep -v homemap.cgi | awk '{print $$1}' | perl -ne 's/://; print if !/.(bak|tdy|ERR)$$/' | sort)

perlcheck:
	${MAKE} _perlcheck 2>/dev/null || ${MAKE} _perlcheck
_perlcheck:
	@echo ${PERL_FILES} | xargs -n1 -P${NCPU} -E " " perl -T -cw

perltidy: perlcheck
	echo ${PERL_FILES} | xargs -n4 -P${NCPU} -E " " perltidy -b
	
clean distclean:
	rm -f *.bak *.tdy *.ERR

	
help:
	@echo "make [ sync-backend | sync-frontend ]"
	@echo "make [ install-backend-lighttpd ]"
	@echo "make [ install-munin-lighttpd ]"
	@echo "make [ install-munin-bbbike | install-munin-bbbike-extract ]"
	@echo "make [ install-munin-xen ]"
	@echo "make [ crontab-root ]"
	@echo "make [ perltidy | distclean ]"
	@echo ""
	@echo "for bbbike.de: "
	@echo "make MUNIN_BBBIKE=\"bbbike-output bbbike-pref bbbike-route bbbike-appid\" install-munin-bbbike"

