all: perltidy

ALL=	bbbike-world-kml \
	berlin-coords-data \
	new-city \
	opensearch-suggestion \
	opensearch-suggestion-gps \
	strasse-str \
	livesearch.cgi \
	streetnames-gps \
	extract-streetnames-osm \
	bbbike-db \
	tagcloud \


perltidy:
	perltidy -b ${ALL}

clean:
	rm -f *.bak *.tdy
