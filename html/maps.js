/* depricated JavaScript file */

var city = "";

function homemap_street(event) {
    var target = (event.target) ? event.target : event.srcElement;
    var street;

    // mouse event
    if (!target.id) {
        street = $(target).attr("title");
    }

    // key events in input field
    else {
        var ac_id = $("div.autocomplete");
        if (target.id == "suggest_start") {
            street = $(ac_id[0]).find("div.selected").attr("title") || $("input#suggest_start").attr("value");
        } else {
            street = $(ac_id[1]).find("div.selected").attr("title") || $("input#suggest_ziel").attr("value");
        }
    }

    if (street == undefined || street.length <= 2) {
        street = ""
    }
    // $("div#foo").text("street: " + street);
    if (street != "") {
        var js_div = $("div#BBBikeGooglemap").contents().find("div#street");
        if (js_div) {
            getStreet(map, city, street);
        }
    }
}

var timeout = null;
var delay = 400; // delay until we render the map

function homemap_street_timer(event, time) {
    // cleanup older calls waiting in queue
    if (timeout != null) {
        clearTimeout(timeout);
    }
    timeout = setTimeout(function () {
        homemap_street(event);
    }, time);
}



// main map object
var map;

function bbbike_maps_init(maptype, marker_list, lang) {


    var routeLinkLabel = "Link to route: ";
    var routeLabel = "Route: ";
    var commonSearchParams = "&pref_seen=1&pref_speed=20&pref_cat=&pref_quality=&pref_green=&scope=;output_as=xml;referer=bbbikegooglemap";
    var routePostParam = "";

    var addRoute = [];
    var undoRoute = [];
    var addRouteOverlay;
    var addRouteOverlay2;

    var userWpts = [];

    var searchStage = 0;

    var isGecko = navigator && navigator.product == "Gecko" ? true : false;
    var dragCursor = isGecko ? '-moz-grab' : 'url("../images/moz_grab.gif"), auto';

    var startIcon = new GIcon(G_DEFAULT_ICON, "../images/flag2_bl_centered.png");
    startIcon.iconAnchor = new GPoint(16, 16);
    startIcon.iconSize = new GSize(32, 32);
    var goalIcon = new GIcon(G_DEFAULT_ICON, "../images/flag_ziel_centered.png");
    goalIcon.iconAnchor = new GPoint(16, 16);
    goalIcon.iconSize = new GSize(32, 32);
    var currentPointMarker = null;
    var currentTempBlockingMarkers = [];

    var startOverlay = null;
    var startPoint = null;
    var goalOverlay = null;
    var goalPoint = null;

    if (GBrowserIsCompatible()) {

        map = new GMap2(document.getElementById("map"));
        // map.disableDoubleClickZoom();
        map.addControl(new GLargeMapControl());
        map.addControl(new GMapTypeControl());

        // var ov = new GOverviewMapControl ();
        // map.addControl( ov );
        // for zoom level, see http://code.google.com/apis/maps/documentation/upgrade.html
        var b = navigator.userAgent.toLowerCase();

        if (marker_list.length > 0) { //  && !(/msie/.test(b) && !/opera/.test(b)) ) {
            var bounds = new GLatLngBounds;
            for (var i = 0; i < marker_list.length; i++) {
                bounds.extend(new GLatLng(marker_list[i][0], marker_list[i][1]));
            }
            map.setCenter(bounds.getCenter());

            var zoom = map.getBoundsZoomLevel(bounds);
            // no zoom level higher than 15
            map.setZoom(zoom < 16 ? zoom : 15);

            // re-center after resize of map window
            $(window).resize(function (e) {
                map.setCenter(bounds.getCenter());
                var zoom = map.getBoundsZoomLevel(bounds)
                map.setZoom(zoom < 16 ? zoom : 15);
            });


            if (marker_list.length == 2) {
                var x1 = marker_list[0][0];
                var y1 = marker_list[0][1];
                var x2 = marker_list[1][0];
                var y2 = marker_list[1][1];

                var route = new GPolyline([
                new GLatLng(x1, y1), new GLatLng(x2, y1), new GLatLng(x2, y2), new GLatLng(x1, y2), new GLatLng(x1, y1)], // first point again
                '#ff0000', 1, null, null, null, {});
                map.addOverlay(route);

                //x1-=1; y1-=1; x2+=1; y2+=1;
                var x3 = x1 - 180;
                var y3 = y1 - 179.99;
                var x4 = x1 + 180;
                var y4 = y1 + 179.99;

                var o = ['#fff', 0, 1, 0.2, 0.2];
                var area_around = new GPolygon([
                new GLatLng(x4, y1), new GLatLng(x3, y1), new GLatLng(x3, y3), new GLatLng(x4, y3), new GLatLng(x4, y1)], // first point again
                o[0], o[1], o[2], o[3], o[4]);
                map.addOverlay(area_around);

                area_around = new GPolygon([
                new GLatLng(x4, y2), new GLatLng(x3, y2), new GLatLng(x3, y4), new GLatLng(x4, y4), new GLatLng(x4, y2)], // first point again
                o[0], o[1], o[2], o[3], o[4]);
                map.addOverlay(area_around);

                area_around = new GPolygon([
                new GLatLng(x2, y1), new GLatLng(x2, y2), new GLatLng(x4, y2), new GLatLng(x4, y1), new GLatLng(x2, y1)], o[0], o[1], o[2], o[3], o[4]);
                map.addOverlay(area_around);

                area_around = new GPolygon([
                new GLatLng(x1, y1), new GLatLng(x1, y2), new GLatLng(x3, y2), new GLatLng(x3, y1), new GLatLng(x1, y1)], o[0], o[1], o[2], o[3], o[4]);
                map.addOverlay(area_around);
            }

        } else {
            // use default zoom level
            // map.setCenter(new GLatLng(48.05000, 7.31000), 17 - 6); // , G_NORMAL_MAP);
        }

        new GKeyboardHandler(map);
    } else {
        document.getElementById("map").innerHTML = '<p class="large-error">Sorry, your browser is not supported by <a href="http://maps.google.com/support">Google Maps</a></p>';
    }

    var copyright = new GCopyright(1, new GLatLngBounds(new GLatLng(-90, -180), new GLatLng(90, 180)), 0, '(<a rel="license" target="_ccbysa" href="http://creativecommons.org/licenses/by-sa/2.0/">CC-BY-SA</a>)');
    var copyrightCollection = new GCopyrightCollection('Map data &copy; 2010 <a target="_osm" href="http://www.openstreetmap.org/">OpenStreetMap</a> Contributors');
    copyrightCollection.addCopyright(copyright);

    map.addMapType(G_PHYSICAL_MAP);

    var tilelayers_mapnik = new Array();
    tilelayers_mapnik[0] = new GTileLayer(copyrightCollection, 0, 18);
    tilelayers_mapnik[0].getTileUrl = GetTileUrl_Mapnik;
    tilelayers_mapnik[0].isPng = function () {
        return true;
    };
    tilelayers_mapnik[0].getOpacity = function () {
        return 1.0;
    };
    var mapnik_map = new GMapType(tilelayers_mapnik, new GMercatorProjection(19), "Mapnik", {
        urlArg: 'mapnik',
        linkColor: '#000000'
    });
    map.addMapType(mapnik_map);

    var tilelayers_tah = new Array();
    tilelayers_tah[0] = new GTileLayer(copyrightCollection, 0, 17);
    tilelayers_tah[0].getTileUrl = GetTileUrl_TaH;
    tilelayers_tah[0].isPng = function () {
        return true;
    };
    tilelayers_tah[0].getOpacity = function () {
        return 1.0;
    };
    var tah_map = new GMapType(tilelayers_tah, new GMercatorProjection(19), "T@H", {
        urlArg: 'tah',
        linkColor: '#000000'
    });
    // map.addMapType(tah_map);
    var tilelayers_cycle = new Array();
    tilelayers_cycle[0] = new GTileLayer(copyrightCollection, 0, 16);
    tilelayers_cycle[0].getTileUrl = GetTileUrl_cycle;
    tilelayers_cycle[0].isPng = function () {
        return true;
    };
    tilelayers_cycle[0].getOpacity = function () {
        return 1.0;
    };
    var cycle_map = new GMapType(tilelayers_cycle, new GMercatorProjection(19), "Cycle", {
        urlArg: 'cycle',
        linkColor: '#000000'
    });
    map.addMapType(cycle_map);

    // map.setMapType(cycle_map);
    var default_maptype = maptype == "normal" ? 'G_NORMAL_MAP' : maptype == "satelite" ? 'G_SATELLITE_MAP' : maptype == "hybrid" ? 'G_HYBRID_MAP' : maptype == "physical" ? 'G_PHYSICAL_MAP' : maptype == "mapnik" ? mapnik_map : maptype == "cycle" ? cycle_map : maptype == "tah" ? tah_map : mapnik_map;

    map.setMapType(default_maptype);
    // map.enableScrollWheelZoom();
}

function GetTileUrl_Mapnik(a, z) {
    return "http://tile.openstreetmap.org/" + z + "/" + a.x + "/" + a.y + ".png";
}

function GetTileUrl_TaH(a, z) {
    return "http://tah.openstreetmap.org/Tiles/tile/" + z + "/" + a.x + "/" + a.y + ".png";
}

function GetTileUrl_cycle(a, z) {
    return "http://a.tile.opencyclemap.org/cycle/" + z + "/" + a.x + "/" + a.y + ".png";
}


var street = "";
var street_cache = [];
var data_cache = [];

function getStreet(map, city, street) {
    var url = encodeURI("/cgi/street-coord.cgi?namespace=0;city=" + city + "&query=" + street);

    // cleanup map
    for (var i = 0; i < street_cache.length; i++) {
        map.removeOverlay(street_cache[i]);
    }

    // read data from cache
    street_cache = [];
    if (data_cache[url] != undefined) {
        return plotStreet(data_cache[url]);
    }

    // plot street(s) on map

    function plotStreet(data) {
        var js = eval(data);
        var streets_list = js[1];

        for (var i = 0; i < streets_list.length; i++) {
            var streets_route = new Array;
            var s = streets_list[i].split(" ");
            for (var j = 0; j < s.length; j++) {
                var coords = s[j].split(",");
                streets_route.push(new GLatLng(coords[1], coords[0]));
            }
            var route = new GPolyline(streets_route, "", 7, 0.5);
            street_cache.push(route);
            map.addOverlay(route);
        }
    }

    // download street coords with AJAX
    GDownloadUrl(url, function (data, responseCode) {
        // To ensure against HTTP errors that result in null or bad data,
        // always check status code is equal to 200 before processing the data
        if (responseCode == 200) {
            data_cache[url] = data;
            plotStreet(data);
        } else if (responseCode == -1) {
            alert("Data request timed out. Please try later.");
        } else {
            alert("Request resulted in error. Check XML file is retrievable.");
        }
    });
}

// bbbike_maps_init("default", [[48.0500000,7.3100000],[48.1300000,7.4100000]] );
