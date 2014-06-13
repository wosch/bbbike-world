###############################################################
# Copyright (c) 2013-2014 Wolfram Schneider, http://bbbike.org
#

LIB=	bbbike-world-javalibs
DEB_REPO_DIR=   /usr/local/www/debian.bbbike.org/ubuntu
DEB_RELEASE=	trusty

all: help

clean:
	rm -f ${LIB}*.tar.gz ${LIB}*.dsc ${LIB}*.changes

distclean:
	rm -f */debian.log *.deb
	rm -f *.tar.gz *.changes *.dsc

build:
	cd ${LIB}; \
	   dpkg-buildpackage -rfakeroot -us -uc > debian.log 2>&1
	@ls -l *.deb

deb-repo:
	dpkg-sig -k 3D084B60 --sign builder 	${LIB}*.deb
	pwd=$$(pwd); cd ${DEB_REPO_DIR}/${DEB_RELEASE}; \
	  reprepro -Vb . removematched ${DEB_RELEASE} ${LIB}-misc; \
	  reprepro -Vb . includedeb ${DEB_RELEASE} $$pwd/${LIB}*.deb

deb-bin:
	${MAKE} LIB=bbbike-world-bin distclean build deb-repo
	${MAKE} LIB=bbbike-world-javalibs distclean build deb-repo

help:
	@echo ""
	@echo "  make [ clean | distclean | build | deb-repo ]"
	@echo ""
	@echo "  make LIB=bbbike-world-bin distclean build deb-repo"
	@echo "  make LIB=bbbike-world-javalibs distclean build deb-repo"

