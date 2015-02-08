###############################################################
# Copyright (c) 2008-2015 Wolfram Schneider, http://bbbike.org
#
# munin setup
#

MUNIN_BBBIKE= 		bbbike-ajax \
			bbbike-output \
			bbbike-pref \
			bbbike-maptype \
			bbbike-route \
			bbbike-processes \
			bbbike-appid

MUNIN_BBBIKE_EXTRACT= 	bbbike-extract-diskusage \
			bbbike-extract-files \
			bbbike-extract-size \
			bbbike-extract-jobs \
			bbbike-extract-size-median

MUNIN_PLUGINS_DIR=	/etc/munin/plugins

all: help

install-munin-xen:
	sudo ln -fs `pwd`/../src/munin/xen_multi ${MUNIN_PLUGINS_DIR}
	${MAKE} munin-restart
	@echo  "don't forget to update /etc/munin/plugin-conf.d/munin-node, see ./README"
	
install-munin-bbbike:
	for i in ${MUNIN_BBBIKE}; do \
	   sudo ln -fs `pwd`/plugins/bbbike ${MUNIN_PLUGINS_DIR}/$$i; \
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
	${MAKE} munin-restart

munin-restart:
	sudo /etc/init.d/munin-node stop
	sleep 0.2
	sudo /etc/init.d/munin-node start

##################################################################################
# perltidy section
#
NCPU=`../../bin/ncpu`
PERL_FILES:=	$(shell file * */* | egrep -iw perl | awk '{print $$1}' | perl -ne 's/://; print if !/.(bak|tdy|ERR)$$/' | sort)

perlcheck:
	${MAKE} _perlcheck 2>/dev/null || ${MAKE} _perlcheck
_perlcheck:
	@echo ${PERL_FILES} | xargs -n1 -P${NCPU} -E " " perl -T -cw

perltidy: perlcheck
	echo ${PERL_FILES} | xargs -n4 -P${NCPU} -E " " perltidy -b
	
clean distclean:
	rm -f *.bak *.tdy *.ERR

	
help:
	@echo "make [ install-munin-xen | install-munin-bbbike | install-munin-bbbike-extract ]"
	@echo "     [ perltidy | distclean ]"
	@echo ""
	@echo "for bbbike.de: "
	@echo "make MUNIN_BBBIKE=\"bbbike-output bbbike-pref bbbike-route bbbike-appid\" install-munin-bbbike"

