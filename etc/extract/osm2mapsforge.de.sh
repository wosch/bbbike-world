cat << EOF
Map data (c) OpenStreetMap contributors, http://www.openstreetmap.org
Extracts created by BBBike, http://BBBike.org
mapsforge map writer v0.3.0 by http://mapsforge.org


Please read the OSM wiki how to install the maps on your Android device:

  http://wiki.openstreetmap.org/wiki/Mapsforge
  http://code.google.com/p/mapsforge/


Diese mapsforge Karte wurde erzeugt am: $date
Mapsforge Kartenstil: $map_style
GPS Rechteck Koordinaten (lng,lat): $BBBIKE_EXTRACT_COORDS
Script URL: $BBBIKE_EXTRACT_URL
Name des Gebietes: $city


Spenden sind willkommen! Du kannst uns via PayPal, Flattr oder Bankueberweisung
unterstuetzen: http://www.bbbike.org/community.de.html

Danke, Wolfram Schneider

--
http://www.BBBike.org - Dein Fahrrad-Routenplaner
EOF
