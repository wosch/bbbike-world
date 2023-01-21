###############################################################
# Copyright (c) 2008-2018 Wolfram Schneider, https://bbbike.org
#
# munin setup
#

MUNIN_BBBIKE_SYSTEM= 	bbbike-processes \
			bbbike-data-status \
			bbbike-planet-status \
			bbbike-tagname-status \
			bbbike-git-status

MUNIN_BBBIKE_WEB=	bbbike-services-ajax \
			bbbike-services-output \
			bbbike-services-pref \
			bbbike-services-maptype \
			bbbike-services-route \
			bbbike-services-appid

MUNIN_EXTRACT= 		extract-diskusage \
			extract-files \
			extract-size \
			extract-jobs \
			extract-users \
			extract-wait \
			extract-download \
			extract-stale

MUNIN_EXTRACT_WEB= 	extract-services-format \
			extract-services-tilesize


MUNIN_VARNISH=	data_structures vcl_and_bans lru objects_per_objhead obj_sendfile_vs_write losthdr esi hcb shm shm_writes overflow session session_herd	

MUNIN_PLUGINS_DIR=	/etc/munin/plugins
MUNIN_PLUGIN_CONF_DIR=	/etc/munin/plugin-conf.d/
MUNIN_LIGHTTPD= lighttpd_accesses lighttpd_busyservers lighttpd_idleservers lighttpd_kbytes lighttpd_uptime     


all: help

install-munin-xen:
	sudo ln -fs $$(pwd)/../../src/munin/xen_multi ${MUNIN_PLUGINS_DIR}
	${MAKE} munin-restart
	${MAKE} help-update

install-munin-jenkins:
	sudo ln -fs $$(pwd)/../../src/munin/jenkins ${MUNIN_PLUGINS_DIR}/jenkins_queue
	sudo ln -fs $$(pwd)/../../src/munin/jenkins ${MUNIN_PLUGINS_DIR}/jenkins_results
	sudo ln -fs $$(pwd)/../../src/munin/jenkins ${MUNIN_PLUGINS_DIR}/jenkins_running
	sudo ln -fs $$(pwd)/plugin-conf.d/jenkins   ${MUNIN_PLUGIN_CONF_DIR}
	${MAKE} munin-restart
	${MAKE} help-update

# sudo apt-get install python-apt
install-munin-apt:
	sudo ln -fs $$(pwd)/../../src/munin/deb_packages ${MUNIN_PLUGINS_DIR}
	sudo ln -fs $$(pwd)/plugin-conf.d/deb_packages   ${MUNIN_PLUGIN_CONF_DIR}
	${MAKE} munin-restart
	${MAKE} help-update

install-munin-stats:
	cd ${MUNIN_PLUGINS_DIR} && sudo ln -fs /usr/share/munin/plugins/munin_stats .
	${MAKE} munin-restart

# sensors
install-munin-acpi:
	cd ${MUNIN_PLUGINS_DIR} && sudo ln -fs /usr/local/www/bbbike/world/src/munin/acpi .
	${MAKE} munin-restart



help-update:
	@echo ""
	@echo  "don't forget to update /etc/munin/plugin-conf.d/munin-node, see ./README"

install-munin-bbbike: clean-install install-munin-bbbike-system install-munin-bbbike-web \
			install-munin-extract install-munin-apt

install-munin-bbbike-system:
	for i in ${MUNIN_BBBIKE_SYSTEM}; do \
	   sudo ln -fs `pwd`/plugins/$$i ${MUNIN_PLUGINS_DIR}/$$i; \
	done
	sudo ln -fs $$(pwd)/plugin-conf.d/bbbike-system   ${MUNIN_PLUGIN_CONF_DIR}
	${MAKE} munin-restart
	${MAKE} help-update
	
	
install-munin-bbbike-web: 
	for i in ${MUNIN_BBBIKE_WEB}; do \
	   sudo ln -fs `pwd`/plugins/bbbike-services ${MUNIN_PLUGINS_DIR}/$$i; \
	done
	${MAKE} munin-restart

install-munin-extract-web: 
	for i in ${MUNIN_EXTRACT_WEB}; do \
	   sudo ln -fs `pwd`/plugins/extract-services ${MUNIN_PLUGINS_DIR}/$$i; \
	done
	${MAKE} munin-restart


install-munin-varnish: 
	for i in ${MUNIN_VARNISH}; do \
	   sudo ln -fs /usr/share/munin/plugins/varnish_ ${MUNIN_PLUGINS_DIR}/varnish_$$i; \
	done
	${MAKE} munin-restart

install-munin-extract: 
	sudo ln -fs `pwd`/plugins/extract-services ${MUNIN_PLUGINS_DIR}/extract-services; \
	for i in ${MUNIN_EXTRACT}; do \
	   sudo ln -fs `pwd`/plugins/$$i ${MUNIN_PLUGINS_DIR}/$$i; \
	done
	sudo ln -fs ${MUNIN_PLUGINS_DIR}/extract-jobs ${MUNIN_PLUGINS_DIR}/extract-pro-jobs
	sudo ln -fs ${MUNIN_PLUGINS_DIR}/extract-users ${MUNIN_PLUGINS_DIR}/extract-pro-users
	sudo ln -fs ${MUNIN_PLUGINS_DIR}/extract-wait ${MUNIN_PLUGINS_DIR}/extract-wait-new
	${MAKE} install-munin-extract-web

install-munin-lighttpd:
	for i in ${MUNIN_LIGHTTPD}; do \
	    sudo ln -fs `pwd`/../../src/munin/munin-lighttpd ${MUNIN_PLUGINS_DIR}/$$i; \
	done
	${MAKE} munin-restart

munin-restart:
	sudo /etc/init.d/munin-node stop
	sleep 0.2
	sudo /etc/init.d/munin-node start

##################################################################################
# perltidy section
#
NCPU=`../../bin/ncpu`
PERL_FILES:=	$(shell file * */* | egrep -w 'perl|Perl|Perl5' | awk '{print $$1}' | perl -ne 's/://; print if !/.(bak|tdy|ERR)$$/' | sort)

perlcheck:
	${MAKE} _perlcheck 2>/dev/null || ${MAKE} _perlcheck

_perlcheck:
	@echo "Check perl modules/scripts: ${PERL_FILES}"
	@echo ${PERL_FILES} | xargs -n1 -P${NCPU} -E " " perl -T -cw

perltidy: perlcheck
	echo ${PERL_FILES} | xargs -n4 -P${NCPU} -E " " perltidy -b
	
clean distclean:
	rm -f *.bak *.tdy *.ERR
	rm -f plugins/*.bak plugins/*.tdy

clean-install:
	sudo rm -f ${MUNIN_PLUGINS_DIR}/bbbike-* ${MUNIN_PLUGINS_DIR}/extract-*
	
help:
	@echo "make install-munin-bbbike"
	@echo "make install-munin-xen"
	@echo "make install-munin-jenkins"
	@echo ""
	@echo "make install-munin-apt"
	@echo "make install-munin-acpi"
	@echo "make install-munin-stats"
	@echo ""
	@echo "make install-munin-bbbike-system"
	@echo "make install-munin-bbbike-web"
	@echo "make install-munin-extract"
	@echo "make install-munin-extract-web"
	@echo ""
	@echo "make install-munin-lighttpd"
	@echo "make install-munin-varnish"
	@echo ""
	@echo "make munin-restart" 
	@echo "make perltidy"
	@echo "make distclean"
	@echo "make clean-install"
	@echo ""
	@echo "for bbbike.de: "
	@echo "make MUNIN_BBBIKE=\"bbbike-output bbbike-pref bbbike-route bbbike-appid\" install-munin-bbbike"

