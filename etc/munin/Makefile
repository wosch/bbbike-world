###############################################################
# Copyright (c) 2008-2015 Wolfram Schneider, http://bbbike.org
#
# munin setup
#

MUNIN_BBBIKE_SYSTEM= 	bbbike-processes

MUNIN_BBBIKE_WEB=	bbbike-ajax \
			bbbike-output \
			bbbike-pref \
			bbbike-maptype \
			bbbike-route \
			bbbike-appid

MUNIN_BBBIKE_EXTRACT= 	bbbike-extract-diskusage \
			bbbike-extract-files \
			bbbike-extract-size \
			bbbike-extract-jobs

MUNIN_VARNISH=	data_structures vcl_and_bans lru objects_per_objhead obj_sendfile_vs_write losthdr esi hcb shm shm_writes overflow session session_herd	

MUNIN_PLUGINS_DIR=	/etc/munin/plugins

all: help

install-munin-xen:
	sudo ln -fs `pwd`/../src/munin/xen_multi ${MUNIN_PLUGINS_DIR}
	${MAKE} munin-restart
	${MAKE} help-update

help-update:
	@echo ""
	@echo  "don't forget to update /etc/munin/plugin-conf.d/munin-node, see ./README"

install-munin-bbbike: install-munin-bbbike-system install-munin-bbbike-web install-munin-bbbike-extract

install-munin-bbbike-system:
	for i in ${MUNIN_BBBIKE_SYSTEM}; do \
	   sudo ln -fs `pwd`/plugins/$$i ${MUNIN_PLUGINS_DIR}/$$i; \
	done
	${MAKE} munin-restart
	${MAKE} help-update
	
	
install-munin-bbbike-web: 
	for i in ${MUNIN_BBBIKE_WEB}; do \
	   sudo ln -fs `pwd`/plugins/bbbike ${MUNIN_PLUGINS_DIR}/$$i; \
	done
	${MAKE} munin-restart

install-munin-varnish: 
	for i in ${MUNIN_VARNISH}; do \
	   sudo ln -fs /usr/share/munin/plugins/varnish_ ${MUNIN_PLUGINS_DIR}/varnish_$$i; \
	done
	${MAKE} munin-restart

install-munin-bbbike-extract:
	sudo ln -fs `pwd`/plugins/bbbike-extract ${MUNIN_PLUGINS_DIR}/bbbike-extract; \
	sudo ln -fs `pwd`/plugins/bbbike-extract ${MUNIN_PLUGINS_DIR}/bbbike-extract-tilesize; \
	sudo ln -fs `pwd`/plugins/bbbike-extract ${MUNIN_PLUGINS_DIR}/bbbike-extract-format; \
	for i in ${MUNIN_BBBIKE_EXTRACT}; do \
	   to=`echo $$i | perl -npe 's,munin-,,'`; \
	   sudo ln -fs `pwd`/plugins/$$i ${MUNIN_PLUGINS_DIR}/$$to; \
	done
	sudo ln -fs ${MUNIN_PLUGINS_DIR}/bbbike-extract-jobs ${MUNIN_PLUGINS_DIR}/bbbike-extract-pro-jobs
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

	
help:
	@echo "make [ install-munin-xen | install-munin-varnish ]"
	@echo "     [ install-munin-bbbike ]"
	@echo "     [ install-munin-bbbike-system | install-munin-bbbike-web | install-munin-bbbike-extract ]"
	@echo ""
	@echo "     [ munin-restart ]" 
	@echo "     [ perltidy | distclean ]"
	@echo ""
	@echo "for bbbike.de: "
	@echo "make MUNIN_BBBIKE=\"bbbike-output bbbike-pref bbbike-route bbbike-appid\" install-munin-bbbike"

