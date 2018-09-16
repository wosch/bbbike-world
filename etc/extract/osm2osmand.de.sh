cat << EOF
Map data (c) OpenStreetMap contributors, https://www.openstreetmap.org
Extracts created by BBBike, https://extract.bbbike.org
$BBBIKE_EXTRACT_OSMAND_VERSION by https://github.com/osmandapp/Osmand


Please read the OsmAnd homepage how to use obf files:

  http://osmand.net


Diese Osmand Karte wurde erzeugt am: $date
GPS Rechteck Koordinaten (lng,lat): $BBBIKE_EXTRACT_COORDS
Script URL: $BBBIKE_EXTRACT_URL
Name des Gebietes: $city

Spenden sind willkommen! Du kannst uns via PayPal oder Bankueberweisung
unterstuetzen: https://www.bbbike.org/community.de.html

Danke, Wolfram Schneider

--
BBBike professional plans: https://extract.bbbike.org/support.html
Planet.osm extracts: https://extract.bbbike.org
BBBike Map Compare: https://mc.bbbike.org
EOF
