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


Spenden sind willkommen! 
Du kannst uns via PayPal oder Banküberweisung unterstützen

  https://extract.bbbike.org/community.de.html

Deine Unterstützung hält den BBBike Extract Service am Laufen!
Bitte spende mit PayPal oder Banküberweisung. Wir brauche 20 Euro am Tag bzw.
600 Euro im Monat um die Serverkosten zu decken. Vielen Dank!

Danke, Wolfram Schneider

--
BBBike professional plans: https://extract.bbbike.org/support.html
Planet.osm extracts: https://extract.bbbike.org
BBBike Map Compare: https://mc.bbbike.org
EOF
