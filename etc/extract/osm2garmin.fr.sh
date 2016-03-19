cat << EOF
Map data (c) OpenStreetMap contributors, https://www.openstreetmap.org
Map style (c) by OpenStreetMap.org, BBBike.org, openfietsmap.nl
Extracts created by BBBike, http://BBBike.org
$BBBIKE_EXTRACT_GARMIN_VERSION by http://www.mkgmap.org.uk

Please read the OSM wiki how to install the maps on your GPS device:

  https://wiki.openstreetmap.org/wiki/OSM_Map_On_Garmin#Installing_the_map_onto_your_GPS
  https://wiki.openstreetmap.org/wiki/OSM_Map_On_Garmin/Download


This Garmin map was created on: $date
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

