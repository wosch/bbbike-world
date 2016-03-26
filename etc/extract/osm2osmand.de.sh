cat << EOF
Map data (c) OpenStreetMap contributors, https://www.openstreetmap.org
Extracts created by BBBike, http://extract.bbbike.org
$BBBIKE_EXTRACT_OSMAND_VERSION by https://github.com/osmandapp/Osmand


Please read the OsmAnd homepage how to use obf files:

  http://osmand.net


Diese Osmand Karte wurde erzeugt am: $date
GPS Rechteck Koordinaten (lng,lat): $BBBIKE_EXTRACT_COORDS
Script URL: $BBBIKE_EXTRACT_URL
Name des Gebietes: $city

Spenden sind willkommen! Du kannst uns via PayPal, Flattr oder Bankueberweisung
unterstuetzen: http://www.bbbike.org/community.de.html

Danke, Wolfram Schneider

--
http://www.BBBike.org - Dein Fahrrad-Routenplaner
BBBike Map Compare: http://bbbike.org/mc
EOF
