###############################################################
# Copyright (c) 2013 Wolfram Schneider, http://bbbike.org

LIB=	bbbike-world-javalibs
DEB_REPO_DIR=   /usr/local/www/debian.bbbike.org/debian

all: help

clean:
	rm -f ${LIB}*.tar.gz
	rm -f ${LIB}*.dsc
	rm -f ${LIB}*.changes

distclean:
	rm -f ${LIB}/debian.log
	rm -f ${LIB}*.deb

build:
	cd ${LIB}; \
	   dpkg-buildpackage -rfakeroot -us -uc > debian.log 2>&1
	@ls -l *.deb

deb-repo:
	dpkg-sig -k 3D084B60 --sign builder 	${LIB}*.deb
	pwd=$$(pwd); cd ${DEB_REPO_DIR}; \
	  reprepro -Vb . removematched squeeze 	${LIB}; \
	  reprepro -Vb . includedeb squeeze 	$$pwd/${LIB}*.deb

help:
	@echo ""
	@echo "  make [ clean | distclean | build | deb-repo ]"

