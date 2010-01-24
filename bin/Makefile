all: perltidy

ALL=	bbbike-world-kml \
	berlin-coords-data \
	opensearch-suggestion \
	strasse-str \
	livesearch.cgi \
	streetnames-gps \
	extract-streetnames-osm \
	extract-places-osm \
	bbbike-db \
	tagcloud \
	look.pl \
	gps-region-reduce \


perltidy:
	perltidy -b ${ALL}

clean distlean:
	rm -f *.bak *.tdy
