# Copyright (c) 2011-2013, Wolfram Schneider, http://bbbike.org
#
# create google sitemap for BBBike.org web sites

#SITEMAP_GEN=	$$HOME/opt/sitemap_gen-1.4/sitemap_gen.py
SITEMAP_GEN=	google-sitemapgen
ALL=	bbbike-org download-bbbike-org

files=	 	./files
lastmod_today= ./lastmod-today

all: help

sitemaps: ${ALL}

bbbike-org:
	( cd ../.. ; world/bin/bbbike-db --list) | \
	  perl -ne 'chomp; print qq{$$_/ priority=1.0\0}, qq{en/$$_/ priority=0.75\0}, qq{$$_/streets.html\0}; ' | \
		${lastmod_today} http://www.bbbike.org > ${files}/$@.txt
	${SITEMAP_GEN} --config=$@.xml

download-bbbike-org:
	( cd ../.. ; world/bin/bbbike-db --list) | \
	  perl -ne 'chomp; print qq{$$_/ priority=0.5\0} ' | \
		${lastmod_today} http://download.bbbike.org/osm/bbbike > ${files}/$@.txt
	${SITEMAP_GEN} --config=$@.xml

clean distclean:
	rm -f ${files}/*.txt

help:
	@echo "make [ ${ALL} | help | clean ]"

