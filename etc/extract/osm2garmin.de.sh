cat << EOF
Map data (c) OpenStreetMap contributors, https://www.openstreetmap.org
Extracts created by BBBike, https://extract.bbbike.org
$BBBIKE_EXTRACT_GARMIN_VERSION by https://www.mkgmap.org.uk
Map style (c) by OpenStreetMap.org, BBBike.org, OpenFietsMap.nl, OpenSeaMap.org, OpenTopoMap.org


Please read the OSM wiki how to install the maps on your GPS device:

  https://wiki.openstreetmap.org/wiki/OSM_Map_On_Garmin#Installing_the_map_onto_your_GPS
  https://wiki.openstreetmap.org/wiki/OSM_Map_On_Garmin/Download


Diese Garmin Karte wurde erzeugt am: $date
Garmin Kartenstil: $mkgmap_map_style
GPS Rechteck Koordinaten (lng,lat): $BBBIKE_EXTRACT_COORDS
Script URL: $BBBIKE_EXTRACT_URL
Name des Gebietes: $city


Spenden sind willkommen! Du kannst uns via PayPal oder Bankueberweisung
unterstuetzen: https://www.bbbike.org/community.de.html

Danke, Wolfram Schneider

--
Dein Fahrrad-Routenplaner: https://www.bbbike.org
BBBike Map Compare: https://mc.bbbike.org
EOF
