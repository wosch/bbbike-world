cat << EOF
Map data (c) OpenStreetMap contributors, http://www.openstreetmap.org
Extracts created by BBBike, http://BBBike.org
mkgmap by http://www.mkgmap.org.uk

Please read the OSM wiki how to install the maps on your GPS device:

  http://wiki.openstreetmap.org/wiki/OSM_Map_On_Garmin#Installing_the_map_onto_your_GPS
  http://wiki.openstreetmap.org/wiki/OSM_Map_On_Garmin/Download


Diese Garmin Karte wurde erzeugt am: $date
Garmin Kartenstil: $mkgmap_map_style
GPS Rechteck Koordinaten (lng,lat): $BBBIKE_EXTRACT_COORDS
Script URL: $BBBIKE_EXTRACT_URL
Name des Gebietes: $city


Spenden sind willkommen! Du kannst uns via PayPal, Flattr oder Bank&uuml;berweisung
unterst&uuml;tzen: http://www.bbbike.org/community.de.html

Danke, Wolfram Schneider

--
http://www.BBBike.org - Dein Fahrrad-Routenplaner
EOF
