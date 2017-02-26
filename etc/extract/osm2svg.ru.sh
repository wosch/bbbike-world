cat << EOF
Map data (c) OpenStreetMap contributors, https://www.openstreetmap.org
Extracts created by BBBike, https://extract.bbbike.org
$BBBIKE_EXTRACT_MAPERITIVE_VERSION by http://maperitive.net/

Please read the OSM wiki how to use SVG

  https://en.wikipedia.org/wiki/Scalable_Vector_Graphics
  https://wiki.openstreetmap.org/wiki/SVG


This SVG map was created on: $date
Maperitive map style: $maperitive_map_style
GPS rectangle coordinates (lng,lat): $BBBIKE_EXTRACT_COORDS
Script URL: $BBBIKE_EXTRACT_URL
Name of area: $city

We appreciate any feedback, suggestions and a donation! You can support us via
PayPal, Flattr or bank wire transfer: https://www.BBBike.org/community.html

thanks, Wolfram Schneider

--
Your Cycle Route Planner: https://www.BBBike.org
BBBike Map Compare: https://bbbike.org/mc
EOF
