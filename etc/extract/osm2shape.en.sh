cat << EOF
Map data (c) OpenStreetMap contributors, https://www.openstreetmap.org
Extracts created by BBBike, https://extract.bbbike.org
$BBBIKE_EXTRACT_SHAPE_VERSION by Geofabrik, https://geofabrik.de


Please read the OSM wiki how to use shape files.

  https://wiki.openstreetmap.org/wiki/Shapefiles


This shape file was created on: $date
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
