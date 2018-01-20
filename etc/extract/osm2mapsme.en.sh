cat << EOF
Map data (c) OpenStreetMap contributors, https://www.openstreetmap.org
Extracts created by BBBike, https://extract.bbbike.org
$BBBIKE_EXTRACT_MAPSME_VERSION by https://github.com/mapsme/omim


Please read the maps.me homepage how to use mwm files:

  https://maps.me
  https://support.maps.me
  https://wiki.openstreetmap.org/wiki/Maps.Me

Note: Routing in this extract is not support yet! Sorry.


This maps.me file was created on: $date
GPS rectangle coordinates (lng,lat): $BBBIKE_EXTRACT_COORDS
Script URL: $BBBIKE_EXTRACT_URL
Name of area: $city

We appreciate any feedback, suggestions and a donation! You can support us via
PayPal or bank wire transfer: https://www.bbbike.org/community.html

thanks, Wolfram Schneider

--
Your Cycle Route Planner: https://www.bbbike.org
BBBike Map Compare: https://mc.bbbike.org
EOF
