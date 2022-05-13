cat << EOF
Map data (c) OpenStreetMap contributors, https://www.openstreetmap.org
Extracts created by BBBike, https://extract.bbbike.org
$BBBIKE_EXTRACT_BBBIKE_VERSION by http://bbbike.de

Please read the BBBike.de documentation how to install the maps
on your computer

  http://sourceforge.bbbike.de/downloads.en.html


This bbbike map was created on: $date
GPS rectangle coordinates (lng,lat): $BBBIKE_EXTRACT_COORDS
Script URL: $BBBIKE_EXTRACT_URL
Name of area: $city


We appreciate any feedback, suggestions and a donation!
You can support us via PayPal or bank wire transfer.

  https://extract.bbbike.org/community.html

You can donate any free amount you want. We are happy for every donation,
for 5, 10, 20, or 50 Euro. Whatever you think the service is worth for you,
or you can afford. We need to raise 20 Euro (25 USD) by the end of the day or
600 Euro (700 USD) per month to cover the server costs.
Your donation helps to pay for hosting the service. Many thanks!

thanks, Wolfram Schneider

--
BBBike professional plans: https://extract.bbbike.org/support.html
Planet.osm extracts: https://extract.bbbike.org
BBBike Map Compare: https://mc.bbbike.org
EOF
