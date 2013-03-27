cat << EOF
Map data (c) OpenStreetMap contributors, http://www.openstreetmap.org
Extracts created by BBBike, http://BBBike.org
mapsforge map writer v0.3.0 by http://mapsforge.org


Please read the OSM wiki how to install the maps on your Android device:

  http://wiki.openstreetmap.org/wiki/Mapsforge
  http://code.google.com/p/mapsforge/


This mapsforge map was created on: $date
Mapsforge map style: $map_style
GPS rectangle coordinates (lng,lat): $BBBIKE_EXTRACT_COORDS
Script URL: $BBBIKE_EXTRACT_URL
Name of area: $city

We appreciate any feedback, suggestions and a donation! You can support us via
PayPal, Flattr or bank wire transfer: http://www.BBBike.org/community.html

thanks, Wolfram Schneider

--
http://www.BBBike.org - Your Cycle Route Planner
EOF
