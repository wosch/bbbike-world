# Copyright 2011, Wolfram Schneider, http://bbbike.org
#
# create google sitemap for BBBike.org web sites

SITEMAP_GEN=	$$HOME/opt/sitemap_gen-1.4/sitemap_gen.py
ALL=	bbbike-org

files=	 	./files
lastmod_today= ./lastmod-today

all: help

all2: ${ALL}

bbbike-org:
	( cd ../.. ; world/bin/bbbike-db --list) | \
	  perl -ne 'chomp; print qq{$$_/\0}, qq{$$_/streets.html\0}; ' | \
		${lastmod_today} http://www.bbbike.org > ${files}/$@.txt
	${SITEMAP_GEN} --config=$@.xml

clean:
	rm -f ${files}/*.txt

help:
	@echo "  make [ ${ALL} | help | clean ]"

