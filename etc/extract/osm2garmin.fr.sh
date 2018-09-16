cat << EOF
Map data (c) OpenStreetMap contributors, https://www.openstreetmap.org
Extracts created by BBBike, https://extract.bbbike.org
$BBBIKE_EXTRACT_GARMIN_VERSION by https://www.mkgmap.org.uk
Map style (c) by OpenStreetMap.org, BBBike.org, OpenFietsMap.nl, OpenSeaMap.org, OpenTopoMap.org

Please read the OSM wiki how to install the maps on your GPS device:

  https://wiki.openstreetmap.org/wiki/OSM_Map_On_Garmin#Installing_the_map_onto_your_GPS
  https://wiki.openstreetmap.org/wiki/OSM_Map_On_Garmin/Download


This Garmin map was created on: $date
Garmin map style: $mkgmap_map_style
GPS rectangle coordinates (lng,lat): $BBBIKE_EXTRACT_COORDS
Script URL: $BBBIKE_EXTRACT_URL
Name of area: $city

We appreciate any feedback, suggestions and a donation! You can support us via
PayPal or bank wire transfer: https://www.bbbike.org/community.html

thanks, Wolfram Schneider

--
BBBike professional plans: https://extract.bbbike.org/support.html
Planet.osm extracts: https://extract.bbbike.org
BBBike Map Compare: https://mc.bbbike.org
EOF
