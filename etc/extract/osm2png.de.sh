cat << EOF
Map data (c) OpenStreetMap contributors, https://www.openstreetmap.org
Extracts created by BBBike, https://extract.bbbike.org
$BBBIKE_EXTRACT_MAPERITIVE_VERSION by http://maperitive.net/

Please read the OSM wiki how to use PNG

  https://wiki.openstreetmap.org/wiki/Export
  https://en.wikipedia.org/wiki/Portable_Network_Graphics

 
Diese PNG Karte wurde erzeugt am: $date
Garmin Kartenstil: $maperitive_map_style
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
