cat << EOF
Map data (c) OpenStreetMap contributors, http://www.openstreetmap.org
Extracts created by BBBike, http://BBBike.org
mkgmap by http://www.mkgmap.org.uk

Please read the OSM wiki how to install the maps on your GPS device:

  http://wiki.openstreetmap.org/wiki/OSM_Map_On_Garmin#Installing_the_map_onto_your_GPS
  http://wiki.openstreetmap.org/wiki/OSM_Map_On_Garmin/Download


This garmin map was created on: $date
Garmin map style: $mkgmap_map_style
GPS rectangle coordinates (lng,lat): $BBBIKE_EXTRACT_COORDS
Script URL: $BBBIKE_EXTRACT_URL
Name of area: $city

We appreciate any feedback, suggestions and a donation! You can support us via
PayPal, Flattr or bank wire transfer: http://www.BBBike.org/community.html

thanks, Wolfram Schneider

--
http://www.BBBike.org - Your Cycle Route Planner
EOF

