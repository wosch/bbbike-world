cat << EOF
Map data (c) OpenStreetMap contributors, https://www.openstreetmap.org
Extracts created by BBBike, https://extract.bbbike.org
$BBBIKE_EXTRACT_MAPERITIVE_VERSION by http://maperitive.net/

Please read the OSM wiki how to use SVG

  https://en.wikipedia.org/wiki/Scalable_Vector_Graphics
  https://wiki.openstreetmap.org/wiki/SVG


Diese SVG Karte wurde erzeugt am: $date
Garmin Kartenstil: $maperitive_map_style
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
