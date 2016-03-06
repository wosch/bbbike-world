###############################################################
# Copyright (c) 2013-2014 Wolfram Schneider, http://bbbike.org
#
# run me from ./<deb_release>/deb/

DEB_VENDOR=	ubuntu
DEB_RELEASE=	trusty
DEB_REPO_DIR=   /usr/local/www/debian.bbbike.org/${DEB_VENDOR}
LIB=	bbbike-world-javalibs
COPY_DEB?=	true
DEB_REPO?=	deb-repo
_tmp=	../../../../../tmp/deb/${DEB_VENDOR}/${DEB_RELEASE}

all: help

clean:
	rm -f ${LIB}*.tar.gz ${LIB}*.dsc ${LIB}*.changes
	rm -f */debian.log
	rm -f *.tar.gz *.changes *.dsc
	rm -f */debian/debhelper.log
	rm -f */debian/substvars
	rm -f */debian/files
	rm -rf */debian/tmp

distclean: clean
	rm -f *.deb
	rm -rf */debian/src

build:
	cd ${LIB}; \
	   dpkg-buildpackage -rfakeroot -us -uc #> debian.log 2>&1
	@ls -l *.deb
	if ${COPY_DEB}; then \
	  mkdir -p ${_tmp} && cp -f *.deb ${_tmp}; \
	fi

deb-repo:
	dpkg-sig -k 3D084B60 --sign builder 	${LIB}*.deb
	pwd=$$(pwd); cd ${DEB_REPO_DIR}/${DEB_RELEASE}; \
	  reprepro --ignore=undefinedtarget -Vb . removematched ${DEB_RELEASE} ${LIB}-misc; \
	  reprepro --ignore=undefinedtarget -Vb . includedeb ${DEB_RELEASE} $$pwd/${LIB}*.deb

deb-bin:
	${MAKE} -f ../../Makefile distclean
	${MAKE} -f ../../Makefile LIB=bbbike-world-bin clean build ${DEB_REPO}
	${MAKE} -f ../../Makefile LIB=bbbike-world-javalibs clean build ${DEB_REPO}
	${MAKE} -f ../../Makefile clean

deb-bin-java:
	#${MAKE} -f ../../Makefile distclean
	${MAKE} -f ../../Makefile LIB=bbbike-world-javalibs clean build ${DEB_REPO}
	${MAKE} -f ../../Makefile clean

deb-bin-x86:
	#${MAKE} -f ../../Makefile distclean
	${MAKE} -f ../../Makefile LIB=bbbike-world-bin clean build ${DEB_REPO}
	${MAKE} -f ../../Makefile clean

help:
	@echo ""
	@echo "  make [ clean | distclean | build | deb-repo ]"
	@echo ""
	@echo "  make LIB=bbbike-world-bin distclean build deb-repo"
	@echo "  make LIB=bbbike-world-javalibs distclean build deb-repo"

