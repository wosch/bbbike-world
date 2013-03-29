LIB=	bbbike-world-javalibs

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
	reprepro -Vb . removematched squeeze 	${LIB}*.deb
	reprepro -Vb . includedeb squeeze 	${LIB}*.deb

help:
	@echo ""
	@echo "  make [ clean | distclean | build | deb-repo ]"

