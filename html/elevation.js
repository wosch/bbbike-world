/* depricated JavaScript file */

/*
 Google Maps API v3 is required!

<script type="text/javascript" src="http://www.google.com/jsapi"></script>
<script type="text/javascript" src="http://maps.google.com/maps/api/js?sensor=false"></script>

//////////////////////////////////////////////////
// external variables
//
// list of points in a route
//   var marker_list = [ [47.53301,7.59612], [47.53297,7.59599], [47.53268,7.59506], ... ] 
// the global map
//   var map;
//
*/

// var map = null;
var chart = null;

var geocoderService = null;
var elevationService = null;
var directionsService = null;

var mousemarker = null;
var markers = [];
var polyline = null;
var elevations = null;

var SAMPLES = 400;

var examples = [{
    // Challenger Deep
    latlngs: [
        [43.304945, 5.4120598],
        [43.3041957, 5.4121212],
        [43.3043388, 5.4138052],
        [43.3039348, 5.4187127],
        [43.3037338, 5.4192019],
        [43.3040248, 5.4225599],
        [43.3032311, 5.4496462],
        [43.3030345, 5.4520411],
        [43.3014697, 5.4574281],
        [43.3002063, 5.4769171],
        [43.2893539, 5.4965152],
        [43.2868045, 5.5141309],
        [43.2854258, 5.5540415],
        [43.2860006, 5.5551744],
        [43.2877792, 5.5812209],
        [43.2874726, 5.5826565],
        [43.2872775, 5.5830016],
        [43.286235, 5.5874039],
        [43.2917601, 5.5878209],
        [43.2929885, 5.593981], ],
    mapType: google.maps.MapTypeId.ROADMAP,
    travelMode: 'direct'
}];

// Load the Visualization API and the piechart package.
google.load("visualization", "1", {
    packages: ["columnchart"]
});

// Set a callback to run when the Google Visualization API is loaded.
// google.setOnLoadCallback(elevation_initialize);

function elevation_initialize(slippymap, opt) {
    var myLatlng = new google.maps.LatLng(15, 0);
    var myOptions = {
        zoom: 1,
        center: myLatlng,
        // mapTypeId: google.maps.MapTypeId.TERRAIN
    }

    if (slippymap) {
        map = slippymap;
    } else {
        map = new google.maps.Map(document.getElementById("map")); //, myOptions);
    }

    chart = new google.visualization.ColumnChart(document.getElementById('chart_div'));

    geocoderService = new google.maps.Geocoder();
    elevationService = new google.maps.ElevationService();
    directionsService = new google.maps.DirectionsService();

/* 
    google.maps.event.addListener(map, 'click', function(event) {
      addMarker(event.latLng, true);
    });
    */

    google.visualization.events.addListener(chart, 'onmouseover', function (e) {
        if (mousemarker == null) {
            mousemarker = new google.maps.Marker({
                position: elevations[e.row].location,
                map: map,
                icon: "http://maps.google.com/mapfiles/ms/icons/green-dot.png"
            });
        } else {
            mousemarker.setPosition(elevations[e.row].location);
        }
    });

    // loadExample(0);
    loadRoute(opt);
}

// Takes an array of ElevationResult objects, draws the path on the map
// and plots the elevation profile on a GViz ColumnChart

function plotElevation(results) {
    if (results == null) {
        alert("Sorry, no elevation results are available. Plot the route only.");
        return plotRouteOnly();
    }

    elevations = results;

    var path = [];
    for (var i = 0; i < results.length; i++) {
        path.push(elevations[i].location);
    }

    if (polyline) {
        polyline.setMap(null);
    }

    polyline = new google.maps.Polyline({
        path: path,
        clickable: true,
        strokeColor: '#00FF00',
        strokeWeight: 8,
        strokeOpacity: 0.6,
        map: map
    });

    var data = new google.visualization.DataTable();
    data.addColumn('string', 'Sample');
    data.addColumn('number', 'Elevation');
    for (var i = 0; i < results.length; i++) {
        data.addRow(['', elevations[i].elevation]);
    }

    document.getElementById('chart_div').style.display = 'block';
    chart.draw(data, {
        // width: '800',
        // height: 200,
        legend: 'none',
        titleY: 'Elevation (m)',
        focusBorderColor: '#00ff00'
    });
}

// fallback, plot only the  route without elevation 

function plotRouteOnly() {
    var path = [];
    for (var i in marker_list) {
        path.push(new google.maps.LatLng(marker_list[i][0], marker_list[i][1]));
    }

    polyline = new google.maps.Polyline({
        path: path,
        clickable: true,
        strokeColor: '#008800',
        strokeWeight: 8,
        strokeOpacity: 0.6,
        map: map
    });
}

/*    
    var data = new google.visualization.DataTable();
    data.addColumn('string', 'Sample');
    data.addColumn('number', 'Elevation');
  */

// Remove the green rollover marker when the mouse leaves the chart

function clearMouseMarker() {
    if (mousemarker != null) {
        mousemarker.setMap(null);
        mousemarker = null;
    }
}

// Add a marker and trigger recalculation of the path and elevation

function addMarker(latlng, doQuery) {
    if (markers.length < 800) {

        var marker = new google.maps.Marker({
            position: latlng,
            // map: map,
            // draggable: true
        })

        // google.maps.event.addListener(marker, 'dragend', function(e) { updateElevation(); });
        markers.push(marker);

        if (doQuery) {
            updateElevation();
        }
    }
}


// Trigger the elevation query for point to point
// or submit a directions request for the path between points

function updateElevation() {

    if (markers.length > 1) {
        var latlngs = [];

        // only 500 elevation points can be showed
        // skip every second/third/fourth etc. if there are more
        var select = parseInt((markers.length + SAMPLES) / SAMPLES);

        for (var i in markers) {
            if (i % select == 0) {
                latlngs.push(markers[i].getPosition())
            }
        }

        elevationService.getElevationAlongPath({
            path: latlngs,
            samples: SAMPLES
        }, plotElevation);

    }
}

function loadExample(n) {
    reset();
    map.setMapTypeId(examples[n].mapType);
    // document.getElementById('mode').value = examples[n].travelMode;
    var bounds = new google.maps.LatLngBounds();
    for (var i = 0; i < examples[n].latlngs.length; i++) {
        var latlng = new google.maps.LatLng(
        examples[n].latlngs[i][0], examples[n].latlngs[i][1]);
        addMarker(latlng, false);
        bounds.extend(latlng);
    }
    map.fitBounds(bounds);
    updateElevation();
}

function loadRoute(opt) {
    reset();
    // map.setMapTypeId( google.maps.MapTypeId.ROADMAP );
    if (opt.maptype) {
        map.setMapTypeId(opt.maptype);
    }

    var bounds = new google.maps.LatLngBounds();
    for (var i = 0; i < marker_list.length; i++) {
        var latlng = new google.maps.LatLng(
        marker_list[i][0], marker_list[i][1]);
        addMarker(latlng, false);
        bounds.extend(latlng);
    }
    map.fitBounds(bounds);
    updateElevation();
    RouteMarker(opt);
}


function RouteMarker(opt) {
    var len = marker_list.length;
    var point = new google.maps.LatLng(marker_list[0][0], marker_list[0][1]);
    var point2 = new google.maps.LatLng(marker_list[len - 1][0], marker_list[len - 1][1]);

    var marker = new google.maps.Marker({
        position: point,
        icon: '/images/mm_20_green.png',
        map: map
    });
    var marker2 = new google.maps.Marker({
        position: point2,
        // icon: '/images/mm_20_red.png',
        map: map
    });

    function driving_time(driving_time) {
        var data = "";
        var time = driving_time.split('|');
        for (var i = 0; i < time.length; i++) {
            var t = time[i].split(':');
            data += t[0] + ":" + t[1] + "h (at " + t[2] + "km/h) ";
        }
        return data;
    }

    google.maps.event.addListener(marker, "click", function (event) {
        addInfoWindow(marker)
    });
    google.maps.event.addListener(marker2, "click", function (event) {
        addInfoWindow(marker2)
    });

    function addInfoWindow(marker) {
        if (infoWindow) {
            infoWindow.close();
        }

        infoWindow = new google.maps.InfoWindow({
            maxWidth: 400
        });

        var content = "<div id=\"infoWindowContent\">\n"
        content += "City: " + '<a target="_new" href="/' + opt.city + '/">' + opt.city + '</a>' + "<br/>\n";
        content += "Start: " + opt.startname + "<br/>\n";
        content += "Destination: " + opt.zielname + "<br/>\n";
        content += "Route Length: " + opt.route_length + "km<br/>\n";
        content += "Driving time: " + driving_time(opt.driving_time) + "<br/>\n";
        content += "</div>\n";

        infoWindow.setContent(content);
        infoWindow.open(map, marker);
    };
}



// Clear all overlays, reset the array of points, and hide the chart

function reset() {
    if (polyline) {
        polyline.setMap(null);
    }

    for (var i in markers) {
        markers[i].setMap(null);
    }

    markers = [];

    document.getElementById('chart_div').style.display = 'none';
}
