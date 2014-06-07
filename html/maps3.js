// "use strict"
//////////////////////////////////////////////////////////////////////
// global objects/variables
//
var city = ""; // bbbike city
var map; // main map object
// bbbike options
var bbbike = {
    // map type by google
    mapTypeControlOptions: {
        mapTypeNames: ["ROADMAP", "TERRAIN", "SATELLITE", "HYBRID"],
        // moved to bbbike_maps_init(), because the JS object google is not defiend yet
        mapTypeIds: [],
    },

    // enable Google Arial View: 45 Imagery
    // http://en.wikipedia.org/wiki/Google_Maps#Google_Aerial_View
    mapImagery45: 45,

    // map type by OpenStreetMap & other
    mapType: {
        MapnikMapType: true,
        MapnikDeMapType: true,
        MapnikBwMapType: true,
        CycleMapType: true,
        PublicTransportMapType: true,
        HikeBikeMapType: true,
        BBBikeMapnikMapType: true,
        BBBikeMapnikGermanMapType: true,
        OCMLandscape: true,
        OCMTransport: true,
        MapQuest: true,
        MapQuestSatellite: true,
        Esri: true,
        EsriTopo: true,
        MapBox: true,
        Apple: true,
        Toner: true,
        Watercolor: true,
        NokiaTraffic: true,

        YahooMapMapType: true,
        YahooHybridMapType: false,
        YahooSatelliteMapType: true,

        BingMapMapType: true,
        BingMapOldMapType: false,
        BingHybridMapType: true,
        BingSatelliteMapType: false,
        BingBirdviewMapType: true
    },

    mapPosition: {
        "default": "TOP_RIGHT",
        "mapnik_bw": "BOTTOM_RIGHT",
        "toner": "BOTTOM_RIGHT",
        "nokia_traffic": "BOTTOM_RIGHT",
        "watercolor": "BOTTOM_RIGHT",
        "bing_map": "BOTTOM_RIGHT",
        "bing_map_old": "BOTTOM_RIGHT",
        "bing_hybrid": "BOTTOM_RIGHT",
        "bing_satellite": "BOTTOM_RIGHT",
        "bing_birdview": "BOTTOM_RIGHT",
        "yahoo_map": "BOTTOM_RIGHT",
        "yahoo_hybrid": "BOTTOM_RIGHT",
        "mapquest": "BOTTOM_RIGHT",
        "mapquest_satellite": "BOTTOM_RIGHT",
        "yahoo_satellite": "BOTTOM_RIGHT"
    },

    // optinal layers in google maps or all maps
    mapLayers: {
        TrafficLayer: true,
        BicyclingLayer: true,
        PanoramioLayer: true,
        WeatherLayer: true,

        // enable full screen mode
        SlideShow: true,
        FullScreen: true,
        Smoothness: true,
        VeloLayer: true,
        MaxSpeed: true,
        Replay: true,
        LandShading: true
    },

    // default map
    mapDefault: "mapnik",
    mapDefaultDE: "mapnik_de",

    //mapDefault: "terrain",
    // visible controls
    controls: {
        panControl: true,
        zoomControl: true,
        scaleControl: true,
        overviewMapControl: false
        // bug http://code.google.com/p/gmaps-api-issues/issues/detail?id=3167
    },

    available_google_maps: ["roadmap", "terrain", "satellite", "hybrid"],
    available_custom_maps: ["bing_birdview", "bing_map", "bing_map_old", "bing_hybrid", "bing_satellite", "yahoo_map", "yahoo_hybrid", "yahoo_satellite", "public_transport", "ocm_transport", "ocm_landscape", "hike_bike", "mapnik_de", "mapnik_bw", "mapnik", "cycle", "bbbike_mapnik", "bbbike_mapnik_german", "bbbike_smoothness", "land_shading", "mapquest", "mapquest_satellite", "esri", "esri_topo", "mapbox", "apple", "velo_layer", "max_speed", "toner", "watercolor", "nokia_traffic"],

    area: {
        visible: true,
        greyout: true
    },

    // delay until we render streets on the map
    streetPlotDelay: 400,

    icons: {
        "green": '/images/mm_20_green.png',
        "red": '/images/mm_20_red.png',
        "white": '/images/mm_20_white.png',
        "yellow": '/images/mm_20_yellow.png',
        "bicycle_large": '/images/srtbike.gif',
        "bicycle_ico": '/images/srtbike.ico',

        "blue_dot": "/images/blue-dot.png",
        "green_dot": "/images/green-dot.png",
        "purple_dot": "/images/purple-dot.png",
        "red_dot": "/images/red-dot.png",
        "yellow_dot": "/images/yellow-dot.png",

        "start": "/images/dd-start.png",
        "ziel": "/images/dd-end.png",
        "via": "/images/yellow-dot.png",

        "shadow": "/images/shadow-dot.png",

    },

    maptype_usage: 1,

    granularity: 100000,
    // 5 digits for LatLng after dot
    // position of green/red/yellow search markers
    // 3-4: centered, left top
    // 8: left top
    search_markers_pos: 3.5,

    // change input color to dark green/red/yellow if marker was moved
    dark_icon_colors: 1,

    // IE bugs
    dummy: 0
};

var state = {
    fullscreen: false,
    replay: false,

    // tags to hide in full screen mode
    non_map_tags: ["copyright", "weather_forecast_html", "top_right", "other_cities", "footer", "routing", "route_table", "routelist", "link_list", "bbbike_graphic", "chart_div", "routes", "headlogo", "bottom", "language_switch", "headline", "sidebar"],

    // keep state of non map tags
    non_map_tags_val: {},

    // keep old state of map area
    map_style: {},

    maplist: [],
    slideShowMaps: [],
    markers: [],
    markers_drag: [],

    timeout_crossing: null,
    timeout_menu: null,

    // street lookup events
    timeout: null,

    marker_list: [],

    lang: "en",

    maptype_usage: "",

    // IE bugs
    dummy: 0
};

var layers = {};

//////////////////////////////////////////////////////////////////////
// functions
//

function runReplay(none, none2, toogleColor) {
    // still running
    if (state.replay) {
        state.replay = false;
        return;
    }

    state.replay = true;
    var zoom = map.getZoom();
    var zoom_min = 15;

    // zoom in
    map.setZoom(zoom > zoom_min ? zoom : zoom_min);

    var marker = new google.maps.Marker({
        // position: new google.maps.LatLng(start[0], start[1]),
        icon: bbbike.icons.bicycle_ico,
        map: map
    });

    var cleanup = function (text) {
            if (text) {
                toogleColor(false, text);
            } else {
                state.replay = false;
                toogleColor(true);
            }
        };

    runReplayRouteElevations(0, marker, cleanup, get_driving_time());
    // runReplayRoute(0, marker, cleanup);
}


function runReplayRouteElevations(offset, marker, cleanup, time) {

    // speed to move the map
    var timeout = 200;
    var step = 2;
    if (elevation_obj && elevation_obj.route_length > 0) {
        timeout = timeout * elevation_obj.route_length / 16;
    }

    if (!offset || offset < 0) offset = 0;
    if (offset >= elevations.length) return;

    var seconds = offset / elevations.length * time;

    // last element in route list, or replay was stopped
    if (offset + step == elevations.length || !state.replay) {
        cleanup(readableTime(seconds));
        setTimeout(function () {
            cleanup();
            marker.setMap(null); // delete marker from map
        }, 3000);
        return;
    }

    var start = elevations[offset].location;
    var pos = new google.maps.LatLng(start.lat(), start.lng());

    debug("offset: " + offset + " length: " + marker_list.length + " elevations: " + elevations.length + " timeout: " + timeout + " seconds: " + readableTime(seconds));

    map.panTo(pos);
    marker.setPosition(pos);

    cleanup(readableTime(seconds));
    setTimeout(function () {
        runReplayRouteElevations(offset + step, marker, cleanup, time);
    }, timeout);
}


function runReplayRoute(offset, marker, cleanup) {
    // speed to move the map
    var timeout = 300;
    if (elevation_obj && elevation_obj.route_length > 0) {
        timeout * elevation_obj.route_length / 10;
    }

    if (!offset || offset < 0) offset = 0;
    if (offset >= marker_list.length) return;

    // last element in route list
    if (offset + 1 == marker_list.length) {
        marker.setMap(null); // delete marker from map
        cleanup();
        return;
    }

    var start = marker_list[offset];
    var pos = new google.maps.LatLng(start[0], start[1]);

    marker.setPosition(pos);

    var bounds = new google.maps.LatLngBounds;
    bounds.extend(pos);
    map.setCenter(bounds.getCenter());

    debug("offset: " + offset + " length: " + marker_list.length + " elevations: " + elevations.length + " timeout: " + timeout); // + " height: " + elevations[offset].location.lat);
    setTimeout(function () {
        runReplayRoute(offset + 1, marker, cleanup);
    }, timeout);
}

// "driving_time":"0:27:10|0:19:15|0:15:20|0:13:25" => 0:15:20 => 920 seconds

function readableTime(time) {
    var hour = 0;
    var min = 0;
    var seconds = 0;

    hour = Math.floor(time / 3600);
    min = Math.floor(time / 60);
    seconds = Math.floor(time % 60);

    if (hour < 10) hour = "0" + hour;
    if (min < 10) min = "0" + min;
    if (seconds < 10) seconds = "0" + seconds;
    return hour + ":" + min + ":" + seconds;
}

function get_driving_time() {
    var time = 0;
    if (elevation_obj && elevation_obj.driving_time) {
        var speed = elevation_obj.driving_time.split("|");
        var t = speed[2];
        var t2 = t.split(":");
        time = t2[0] * 3600 + t2[1] * 60 + t2[2] * 1;
    }
    return time;
}

function toogleFullScreen(none, none2, toogleColor) {
    var fullscreen = state.fullscreen;

    for (var i = 0; i < state.non_map_tags.length; i++) {
        tagname = state.non_map_tags[i];
        var tag = document.getElementById(tagname);

        if (tag) {
            if (fullscreen) {
                tag.style.display = state.non_map_tags_val[tagname];
            } else {
                // keep copy of old state
                state.non_map_tags_val[tagname] = tag.style.display;
                tag.style.display = "none";
            }
        }
    }

    resizeFullScreen(fullscreen);
    // toogleColor(fullscreen)
    state.fullscreen = fullscreen ? false : true;
}

// start slide show left from current map

function reorder_map(maplist, currentMaptype) {
    var list = [];
    var later = [];
    var flag = 0;

    // Maps: A B C D E F
    // rotate from D: C B A F E D
    for (var i = 0; i < maplist.length; i++) {
        var maptype = maplist[i];

        // everything which is left of the current map
        if (flag) {
            list.push(maptype);
        } else { // right
            if (maptype == currentMaptype) {
                // list.push(maptype); // start with current map and a delay
                flag = 1;
            }
            later.push(maptype);
        }
    }

    for (var i = 0; i < later.length; i++) {
        list.push(later[i]);
    }

    // debug(list.length + " " + list.join(" "));
    return list;
}

function runSlideShow(none, none2, toogleColor) {
    // stop running slide show
    if (state.slideShowMaps.length > 0) {
        for (var i = 0; i < state.slideShowMaps.length; i++) {
            clearTimeout(state.slideShowMaps[i]);
        }
        state.slideShowMaps = [];
        toogleColor(true);
        return;
    }

    state.slideShowMaps = [];
    var delay = 6000;
    var counter = 0;

    var zoom = map.getZoom();
    var currentMaptype = map.getMapTypeId()
    var maplist = reorder_map(state.maplist, currentMaptype);
    maplist.push(currentMaptype);

    // active, stop button
    toogleColor(false);

    for (var i = 0; i < maplist.length; i++) {
        var maptype = maplist[i];

        (function (maptype, timeout, zoom) {
            var timer = setTimeout(function () {
                map.setMapTypeId(maptype);
                // keep original zoom, could be changed
                // by a map with zoom level up to 14 only
                map.setZoom(zoom);
            }, timeout, zoom);

            state.slideShowMaps.push(timer);
        })(maptype, delay * counter++, zoom);
    }

    // last action, reset color of control
    var timer = setTimeout(function () {
        toogleColor(true)
    }, delay * counter);
    state.slideShowMaps.push(timer);
}

function resizeFullScreen(fullscreen) {
    var tag = document.getElementById("BBBikeGooglemap");

    if (!tag) return;

    var style = ["width", "height", "marginLeft", "marginRight", "right", "left", "top", "bottom"];
    if (!fullscreen) {
        // keep old state
        for (var i = 0; i < style.length; i++) {
            state.map_style[style[i]] = tag.style[style[i]];
            tag.style[style[i]] = "0px";
        }

        tag.style.width = "99%";
        tag.style.height = "99%";
    } else {
        // restore old state
        for (var i = 0; i < style.length; i++) {
            tag.style[style[i]] = state.map_style[style[i]];
        }
    }

    google.maps.event.trigger(map, 'resize');
}


function togglePermaLinks() {
    togglePermaLink("permalink_url");
    togglePermaLink("permalink_url2");
}

function togglePermaLink(id) {
    var permalink = document.getElementById(id);
    if (permalink == null) return;

    if (permalink.style.display == "none") {
        permalink.style.display = "inline";
    } else {
        permalink.style.display = "none";
    };
}


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

function homemap_street_timer(event, time) {
    // cleanup older calls waiting in queue
    if (state.timeout != null) {
        clearTimeout(state.timeout);
    }

    state.timeout = setTimeout(function () {
        homemap_street(event);
    }, time);
}


// test for all google + custom maps

function is_supported_map(maptype) {
    if (is_supported_maptype(maptype, bbbike.available_google_maps) || is_supported_maptype(maptype, bbbike.available_custom_maps)) {
        return 1;
    } else {
        return 0;
    }
}

function is_supported_maptype(maptype, list) {
    if (!list) return 0;

    for (var i = 0; i < list.length; i++) {
        if (list[i] == maptype) return 1;
    }

    return 0;
}

function bbbike_maps_init(maptype, marker_list, lang, without_area, region, zoomParam, layer, is_route) {
    // init google map types by name and order
    for (var i = 0; i < bbbike.mapTypeControlOptions.mapTypeNames.length; i++) {
        bbbike.mapTypeControlOptions.mapTypeIds.push(google.maps.MapTypeId[bbbike.mapTypeControlOptions.mapTypeNames[i]]);
    }
    state.maplist = init_google_map_list();

    if (!is_supported_map(maptype)) {
        maptype = is_european(region) && lang == "de" ? bbbike.mapDefaultDE : bbbike.mapDefault;
        if (city == "bbbike" && is_supported_map("bbbike_mapnik")) {
            maptype = "bbbike_mapnik";
        }
    }
    state.lang = lang;
    state.marker_list = marker_list;

    var routeLinkLabel = "Link to route: ";
    var routeLabel = "Route: ";
    var commonSearchParams = "&pref_seen=1&pref_speed=20&pref_cat=&pref_quality=&pref_green=&scope=;output_as=xml;referer=bbbikegooglemap";

    var startIcon = new google.maps.MarkerImage("../images/flag2_bl_centered.png", new google.maps.Size(20, 32), new google.maps.Point(0, 0), new google.maps.Point(16, 16));
    var goalIcon = new google.maps.MarkerImage("../images/flag_ziel_centered.png", new google.maps.Size(20, 32), new google.maps.Point(0, 0), new google.maps.Point(16, 16));

    map = new google.maps.Map(document.getElementById("map"), {
        zoomControl: bbbike.controls.zoomControl,
        scaleControl: bbbike.controls.scaleControl,
        panControl: bbbike.controls.panControl,
        disableDoubleClickZoom: false,
        mapTypeControlOptions: {
            mapTypeIds: bbbike.mapTypeControlOptions.mapTypeIds
        },
        panControlOptions: {
            position: google.maps.ControlPosition.TOP_LEFT
        },
        zoomControlOptions: {
            position: google.maps.ControlPosition.LEFT_TOP,
            style: google.maps.ZoomControlStyle.LARGE // DEFAULT // SMALL
        },
        overviewMapControl: bbbike.controls.overviewMapControl
    });

    // for zoom level, see http://code.google.com/apis/maps/documentation/upgrade.html
    var b = navigator.userAgent.toLowerCase();

    if (marker_list.length > 0) { //  && !(/msie/.test(b) && !/opera/.test(b)) ) {
        var bounds = new google.maps.LatLngBounds;
        for (var i = 0; i < marker_list.length; i++) {
            bounds.extend(new google.maps.LatLng(marker_list[i][0], marker_list[i][1]));
        }
        map.setCenter(bounds.getCenter());

        // var zoom = map.getBoundsZoomLevel(bounds);
        // improve zoom level, max. area as possible
        var bounds_padding = new google.maps.LatLngBounds;
        if (marker_list.length == 2) {
            var padding_x = 0.10; // make the area smaller by this value to cheat to map.getZoom()
            var padding_y = 0.07;

            bounds_padding.extend(new google.maps.LatLng(marker_list[0][0] + padding_x, marker_list[0][1] + padding_y));
            bounds_padding.extend(new google.maps.LatLng(marker_list[1][0] - padding_x, marker_list[1][1] - padding_y));
            if (!zoomParam) {
                map.fitBounds(bounds_padding);
            }
        } else {
            map.fitBounds(bounds);
        }
        var zoom = map.getZoom();

        // no zoom level higher than 15
        map.setZoom(zoom < 16 ? zoom : 15);

        // alert("zoom: " + zoom + " : " + map.getZoom() + " : " + zoomParam);
        if (zoomParam && parseInt(zoomParam) > 0) {
            map.setZoom(parseInt(zoomParam));
        }

/* XXX: danger!
	    // re-center after resize of map window
	    $(window).resize( function(e) { 
		var current_zoom = map.getZoom();
		// map.setCenter(bounds.getCenter()); 
		var zoom = map.getBoundsZoomLevel(bounds)
		map.fitBounds(bounds_padding);
		var zoom = map.getZoom();
			map.setZoom( zoom < 16 ? zoom : 15); 
	    });
	*/

        $(window).resize(function (e) {
            setMapHeight();
        });


        if (marker_list.length == 2 && without_area != 1 && bbbike.area.visible) {
            var x1 = marker_list[0][0];
            var y1 = marker_list[0][1];
            var x2 = marker_list[1][0];
            var y2 = marker_list[1][1];

            var route = new google.maps.Polyline({
                path: [
                new google.maps.LatLng(x1, y1), new google.maps.LatLng(x2, y1), new google.maps.LatLng(x2, y2), new google.maps.LatLng(x1, y2), new google.maps.LatLng(x1, y1)],
                // first point again
                strokeColor: '#ff0000',
                strokeWeight: 0
            });

            route.setMap(map);

            if (bbbike.area.greyout) {
                //x1-=1; y1-=1; x2+=1; y2+=1;
                var x3 = x1 - 180;
                var y3 = y1 - 179.99;
                var x4 = x1 + 180;
                var y4 = y1 + 179.99;

                var o = ['#ffffff', 0, 1, '#000000', 0.2];
                var area_around = new google.maps.Polygon({
                    paths: [
                    new google.maps.LatLng(x4, y1), new google.maps.LatLng(x3, y1), new google.maps.LatLng(x3, y3), new google.maps.LatLng(x4, y3), new google.maps.LatLng(x4, y1)],
                    // first point again
                    strokeColor: o[0],
                    strokeWeight: o[1],
                    strokeOpacity: o[2],
                    fillOpacity: o[4]
                });
                area_around.setMap(map);

                area_around = new google.maps.Polygon({
                    path: [
                    new google.maps.LatLng(x4, y2), new google.maps.LatLng(x3, y2), new google.maps.LatLng(x3, y4), new google.maps.LatLng(x4, y4), new google.maps.LatLng(x4, y2)],
                    // first point again
                    strokeColor: o[0],
                    strokeWeight: o[1],
                    strokeOpacity: o[2],
                    fillOpacity: o[4]
                });
                area_around.setMap(map);

                area_around = new google.maps.Polygon({
                    path: [
                    new google.maps.LatLng(x2, y1), new google.maps.LatLng(x2, y2), new google.maps.LatLng(x4, y2), new google.maps.LatLng(x4, y1), new google.maps.LatLng(x2, y1)],
                    strokeColor: o[0],
                    strokeWeight: o[1],
                    strokeOpacity: o[2],
                    fillOpacity: o[4]
                });
                area_around.setMap(map);

                area_around = new google.maps.Polygon({
                    path: [
                    new google.maps.LatLng(x1, y1), new google.maps.LatLng(x1, y2), new google.maps.LatLng(x3, y2), new google.maps.LatLng(x3, y1), new google.maps.LatLng(x1, y1)],
                    strokeColor: o[0],
                    strokeWeight: o[1],
                    strokeOpacity: o[2],
                    fillOpacity: o[4]
                });
                area_around.setMap(map);
            }
        }
    }

    function is_european(region) {
        return (region == "de" || region == "eu") ? true : false;
    }

    //
    // see:
    // 	http://wiki.openstreetmap.org/wiki/Slippy_map_tilenames
    //  http://wiki.openstreetmap.org/wiki/Tileserver
    //
    var mapnik_options = {
        bbbike: {
            "name": "Mapnik",
            "description": "Mapnik, by OpenStreetMap.org"
        },
        getTileUrl: function (a, z) {
            return "http://" + randomServerOSM() + ".tile.openstreetmap.org/" + z + "/" + a.x + "/" + a.y + ".png";
        },
        isPng: true,
        opacity: 1.0,
        tileSize: new google.maps.Size(256, 256),
        name: "MAPNIK",
        minZoom: 1,
        maxZoom: 18
    };

    // http://openstreetmap.de/
    var mapnik_de_options = {
        bbbike: {
            "name": "Mapnik (de)",
            "description": "German Mapnik, by OpenStreetMap.de"
        },
        getTileUrl: function (a, z) {
            return "http://" + randomServerOSM(4) + ".tile.openstreetmap.de/tiles/osmde/" + z + "/" + a.x + "/" + a.y + ".png";
        },
        isPng: true,
        opacity: 1.0,
        tileSize: new google.maps.Size(256, 256),
        name: "MAPNIK-DE",
        minZoom: 1,
        maxZoom: 18
    };

    // BBBike data in mapnik
    var bbbike_mapnik_options = {
        bbbike: {
            "name": "BBBike",
            "description": "BBBike Mapnik, by bbbike.de"
        },
        getTileUrl: function (a, z) {
            return "http://" + randomServerOSM(3) + ".tile.bbbike.org/osm/mapnik/" + z + "/" + a.x + "/" + a.y + ".png";
        },
        isPng: true,
        opacity: 1.0,
        tileSize: new google.maps.Size(256, 256),
        name: "BBBIKE-MAPNIK",
        minZoom: 1,
        maxZoom: 18
    };

    // BBBike smoothness overlay
    var bbbike_smoothness_options = {
        bbbike: {
            "name": "BBBike (Smoothness)",
            "description": "BBBike Smoothness, by bbbike.de"
        },
        getTileUrl: function (a, z) {
            return "http://" + randomServerOSM(3) + ".tile.bbbike.org/osm/bbbike-smoothness/" + z + "/" + a.x + "/" + a.y + ".png";
        },
        isPng: true,
        opacity: 1.0,
        tileSize: new google.maps.Size(256, 256),
        name: "BBBIKE-SMOOTHNESS",
        minZoom: 1,
        maxZoom: 18
    };

    var velo_layer_options = {
        bbbike: {
            "name": "Velo-Layer",
            "description": "Velo-Layer, by osm.t-i.ch/bicycle/map"
        },
        getTileUrl: function (a, z) {
            return "http://toolserver.org/tiles/bicycle/" + z + "/" + a.x + "/" + a.y + ".png";
        },
        isPng: true,
        opacity: 1.0,
        tileSize: new google.maps.Size(256, 256),
        name: "VELO-LAYER",
        minZoom: 1,
        maxZoom: 19
    };
    var max_speed_options = {
        bbbike: {
            "name": "Max Speed",
            "description": "Max Speed, by wince.dentro.info/koord/osm/KosmosMap.htm"
        },
        getTileUrl: function (a, z) {
            return "http://wince.dentro.info/koord/osm/tiles/" + z + "/" + a.x + "/" + a.y + ".png";
        },
        isPng: true,
        opacity: 1.0,
        tileSize: new google.maps.Size(256, 256),
        name: "MAX-SPEED",
        minZoom: 1,
        maxZoom: 15
    };

    // Land Shading overlay
    var land_shading_options = {
        bbbike: {
            "name": "Land Shading",
            "description": "Land Shading, by openpistemap.org"
        },
        getTileUrl: function (a, z) {
            return "http://" + "tiles2.openpistemap.org/landshaded/" + z + "/" + a.x + "/" + a.y + ".png";
        },
        isPng: true,
        opacity: 1.0,
        tileSize: new google.maps.Size(256, 256),
        name: "LAND-SHADING",
        minZoom: 1,
        maxZoom: 18
    };

    // BBBike data in mapnik german
    var bbbike_mapnik_german_options = {
        bbbike: {
            "name": "BBBike (de)",
            "description": "BBBike Mapnik German, by bbbike.de"
        },
        getTileUrl: function (a, z) {
            return "http://" + randomServerOSM(3) + ".tile.bbbike.org/osm/mapnik-german/" + z + "/" + a.x + "/" + a.y + ".png";
        },
        isPng: true,
        opacity: 1.0,
        tileSize: new google.maps.Size(256, 256),
        name: "BBBIKE-MAPNIK-GERMAN",
        minZoom: 1,
        maxZoom: 18
    };


    // http://osm.t-i.ch/bicycle/map/
    var mapnik_bw_options = {
        bbbike: {
            "name": "Mapnik (b/w)",
            "description": "Mapnik Black and White, by OpenStreetMap.org and wikimedia.org"
        },
        getTileUrl: function (a, z) {
            return "http://" + randomServerOSM() + ".www.toolserver.org/tiles/bw-mapnik/" + z + "/" + a.x + "/" + a.y + ".png";
        },
        isPng: true,
        opacity: 1.0,
        tileSize: new google.maps.Size(256, 256),
        name: "MAPNIK-BW",
        minZoom: 1,
        maxZoom: 18
    };

    // http://www.öpnvkarte.de/
    var public_transport_options = {
        bbbike: {
            "name": "Public Transport",
            "description": "Public Transport, by öpnvkarte.de and OpenStreetMap.org"
        },
        getTileUrl: function (a, z) {
            return "http://" + randomServerOSM() + ".tile.xn--pnvkarte-m4a.de/tilegen/" + z + "/" + a.x + "/" + a.y + ".png";
        },
        isPng: true,
        opacity: 1.0,
        tileSize: new google.maps.Size(256, 256),
        name: "TAH",
        minZoom: 1,
        maxZoom: 18
    };

    // http://hikebikemap.de/
    var hike_bike_options = {
        bbbike: {
            "name": "Hike&Bike",
            "description": "Hike&Bike, by OpenStreetMap.org and wikimedia.org"
        },
        getTileUrl: function (a, z) {
            return "http://" + randomServerOSM() + ".www.toolserver.org/tiles/hikebike/" + z + "/" + a.x + "/" + a.y + ".png";
        },
        isPng: true,
        opacity: 1.0,
        tileSize: new google.maps.Size(256, 256),
        name: "TAH",
        minZoom: 1,
        maxZoom: 17
    }

    var cycle_options = {
        bbbike: {
            "name": "Cycle",
            "description": "Cycle, by OpenStreetMap"
        },
        getTileUrl: function (a, z) {
            return "http://" + randomServerOSM() + ".tile.opencyclemap.org/cycle/" + z + "/" + a.x + "/" + a.y + ".png";
        },
        isPng: true,
        opacity: 1.0,
        tileSize: new google.maps.Size(256, 256),
        name: "CYCLE",
        minZoom: 1,
        maxZoom: 18
    };

    var ocm_transport_options = {
        bbbike: {
            "name": "Transport",
            "description": "Transport, by OpenCycleMap.org"
        },
        getTileUrl: function (a, z) {
            return "http://" + randomServerOSM() + ".tile2.opencyclemap.org/transport/" + z + "/" + a.x + "/" + a.y + ".png";
        },
        isPng: true,
        opacity: 1.0,
        tileSize: new google.maps.Size(256, 256),
        name: "TRANSPORT",
        minZoom: 1,
        maxZoom: 18
    };

    var ocm_landscape_options = {
        bbbike: {
            "name": "Landscape",
            "description": "Landscape, by OpenCycleMap.org"
        },
        getTileUrl: function (a, z) {
            return "http://" + randomServerOSM() + ".tile3.opencyclemap.org/landscape/" + z + "/" + a.x + "/" + a.y + ".png";
        },
        isPng: true,
        opacity: 1.0,
        tileSize: new google.maps.Size(256, 256),
        name: "LANDSCAPE",
        minZoom: 1,
        maxZoom: 18
    };

    var mapquest_options = {
        bbbike: {
            "name": "MapQuest",
            "description": "MapQuest, by mapquest.com"
        },
        getTileUrl: function (a, z) {
            return "http://otile" + randomServer(4) + ".mqcdn.com/tiles/1.0.0/osm/" + z + "/" + a.x + "/" + a.y + ".png";
        },
        isPng: true,
        opacity: 1.0,
        tileSize: new google.maps.Size(256, 256),
        name: "MapQuest",
        minZoom: 1,
        maxZoom: 19
    };

    var mapquest_satellite_options = {
        bbbike: {
            "name": "MapQuest Sat",
            "description": "MapQuest Satellite, by mapquest.com"
        },
        getTileUrl: function (a, z) {
            return "http://mtile0" + randomServer(4) + ".mqcdn.com/tiles/1.0.0/vy/sat/" + z + "/" + a.x + "/" + a.y + ".png";
        },
        isPng: true,
        opacity: 1.0,
        tileSize: new google.maps.Size(256, 256),
        name: "MapQuest",
        minZoom: 1,
        maxZoom: 19
    };

    var esri_options = {
        bbbike: {
            "name": "Esri",
            "description": "Esri, by arcgisonline.com"
        },
        getTileUrl: function (a, z) {
            return "http://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/" + z + "/" + a.y + "/" + a.x + ".png";
        },
        isPng: true,
        opacity: 1.0,
        tileSize: new google.maps.Size(256, 256),
        name: "ESRI",
        minZoom: 1,
        maxZoom: 18
    };

    var esri_topo_options = {
        bbbike: {
            "name": "Esri Topo",
            "description": "Esri Topo, by arcgisonline.com"
        },
        getTileUrl: function (a, z) {
            return "http://services.arcgisonline.com/ArcGIS/rest/services/World_Topo_Map/MapServer/tile/" + z + "/" + a.y + "/" + a.x + ".png";
        },
        isPng: true,
        opacity: 1.0,
        tileSize: new google.maps.Size(256, 256),
        name: "ESRI-TOPO",
        minZoom: 1,
        maxZoom: 18
    };

    // http://png.maps.yimg.com/png?t=m&v=4.1&s=256&f=j&x=34&y=11&z=12
    // http://png.maps.yimg.com/png?t=m&v=4.1&s=256&f=j&x=34&y=11&z=12
    // http://png.maps.yimg.com/png?t=m&v=4.1&s=256&f=j&x=34&y=11&z=12
    // http://www.guidebee.biz/forum/viewthread.php?tid=71
    var yahoo_map_options = {
        bbbike: {
            "name": "Yahoo",
            "description": "Yahoo, by maps.yahoo.com"
        },
        getTileUrl: function (a, z) {
            return "http://png.maps.yimg.com/png?t=m&v=4.1&s=256&f=j&x=" + a.x + "&y=" + (((1 << z) >> 1) - 1 - a.y) + "&z=" + (18 - z);
        },
        isPng: true,
        opacity: 1.0,
        tileSize: new google.maps.Size(256, 256),
        name: "YAHOO-MAP",
        minZoom: 1,
        maxZoom: 17
    };
    var yahoo_hybrid_options = {
        bbbike: {
            "name": "Yahoo Hybrid",
            "description": "Yahoo Hybrid, by maps.yahoo.com",
        },
        getTileUrl: function (a, z) {
            return "http://us.maps3.yimg.com/aerial.maps.yimg.com/png?v=1.1&t=h&s=256&x=" + a.x + "&y=" + (((1 << z) >> 1) - 1 - a.y) + "&z=" + (18 - z);
        },
        isPng: true,
        opacity: 1.0,
        tileSize: new google.maps.Size(256, 256),
        name: "YAHOO-HYBRID",
        minZoom: 1,
        maxZoom: 17
    };
    var yahoo_satellite_options = {
        bbbike: {
            "name": "Yahoo Sat",
            "description": "Yahoo Satellite, by maps.yahoo.com",
        },
        getTileUrl: function (a, z) {
            return "http://aerial.maps.yimg.com/ximg?t=a&v=1.7&s=256&x=" + a.x + "&y=" + (((1 << z) >> 1) - 1 - a.y) + "&z=" + (18 - z);
        },
        isPng: true,
        opacity: 1.0,
        tileSize: new google.maps.Size(256, 256),
        name: "YAHOO-SATELLITE",
        minZoom: 1,
        maxZoom: 17
    }

    function getTileUrlBing(a, z, type) {
        var fmt = (type == "r" ? "png" : "jpeg");
        var digit = ((a.y & 1) << 1) + (a.x & 1);

        var ret = "http://" + type + digit + ".ortho.tiles.virtualearth.net/tiles/" + type;
        for (var i = z - 1; i >= 0; i--) {
            ret += ((((a.y >> i) & 1) << 1) + ((a.x >> i) & 1));
        }
        ret += "." + fmt + "?g=45";
        return ret;
    }

    var bing_map_old_options = {
        bbbike: {
            "name": "Bing (old)",
            "description": "Bing traditional, by Microsoft"
        },
        getTileUrl: function (a, z) {
            return getTileUrlBing(a, z, "r")
        },
        isPng: true,
        opacity: 1.0,
        tileSize: new google.maps.Size(256, 256),
        name: "BING-MAP-OLD",
        minZoom: 1,
        maxZoom: 19
    };
    var bing_map_options = {
        bbbike: {
            "name": "Bing",
            "description": "Bing, by maps.bing.com and Microsoft"
        },
        getTileUrl: function (a, z) {
            return getTileUrlBingVirtualearth(a, z, "r")
        },
        isPng: true,
        opacity: 1.0,
        tileSize: new google.maps.Size(256, 256),
        name: "BING-MAP",
        minZoom: 1,
        maxZoom: 17
    }

    var bing_hybrid_options = {
        bbbike: {
            "name": "Bing Hybrid",
            "description": "Bing Hybrid, by maps.bing.com and Microsoft"
        },
        getTileUrl: function (a, z) {
            return getTileUrlBing(a, z, "h")
        },
        isPng: false,
        opacity: 1.0,
        tileSize: new google.maps.Size(256, 256),
        name: "BING-MAP",
        minZoom: 1,
        maxZoom: 17
    };
    var bing_satellite_options = {
        bbbike: {
            "name": "Bing Sat",
            "description": "Bing Satellite, by maps.bing.com and Microsoft"
        },
        getTileUrl: function (a, z) {
            return getTileUrlBing(a, z, "a");
        },
        isPng: false,
        opacity: 1.0,
        tileSize: new google.maps.Size(256, 256),
        name: "BING-MAP",
        minZoom: 1,
        maxZoom: 17
    };

    var mapbox_options = {
        bbbike: {
            "name": "MapBox",
            "description": "MapBox OSM, by mapbox.com"
        },
        getTileUrl: function (a, z) {
            return "http://" + randomServerOSM() + ".tiles.mapbox.com/v3/examples.map-vyofok3q/" + z + "/" + a.x + "/" + a.y + ".png";
        },
        isPng: true,
        opacity: 1.0,
        tileSize: new google.maps.Size(256, 256),
        name: "MapQuest",
        minZoom: 1,
        maxZoom: 17
    };

    var apple_options = {
        bbbike: {
            "name": "Apple",
            "description": "Apple iPhone OSM, by apple.com"
        },
        getTileUrl: function (a, z) {
            return "http://gsp2.apple.com/tile?api=1&style=slideshow&layers=default&lang=de_DE&z=" + z + "&x=" + a.x + "&y=" + a.y + "&v=9";
        },
        isPng: true,
        opacity: 1.0,
        tileSize: new google.maps.Size(256, 256),
        name: "apple",
        minZoom: 1,
        maxZoom: 14
    };

    var toner_options = {
        bbbike: {
            "name": "Toner",
            "description": "Toner, by maps.stamen.com"
        },
        getTileUrl: function (a, z) {
            return "http://" + randomServerOSM(4) + ".tile.stamen.com/toner/" + z + "/" + a.x + "/" + a.y + ".png";
        },
        isPng: true,
        opacity: 1.0,
        tileSize: new google.maps.Size(256, 256),
        name: "toner",
        minZoom: 1,
        maxZoom: 19
    };

    var watercolor_options = {
        bbbike: {
            "name": "Watercolor",
            "description": "Watercolor, by maps.stamen.com"
        },
        getTileUrl: function (a, z) {
            return "http://" + randomServerOSM(4) + ".tile.stamen.com/watercolor/" + z + "/" + a.x + "/" + a.y + ".png";
        },
        isPng: true,
        opacity: 1.0,
        tileSize: new google.maps.Size(256, 256),
        name: "toner",
        minZoom: 1,
        maxZoom: 19
    };

    var nokia_traffic_options = {
        bbbike: {
            "name": "NokiaTraffic",
            "description": "Here Traffic, by maps.here.com"
        },
        getTileUrl: function (a, z) {
            return nokia(a, z, "newest/normal.day");
        },
        isPng: true,
        opacity: 1.0,
        tileSize: new google.maps.Size(256, 256),
        name: "nokia_traffic",
        minZoom: 1,
        maxZoom: 19
    };

    //
    // select a tiles random server. The argument is either an interger or a 
    // list of server names , e.g.:
    // list = ["a", "b"]; 
    // list = 4;
    //

    function randomServer(list) {
        var server;

        if (typeof list == "number") {
            server = parseInt(Math.random() * list);
        } else {
            server = list[parseInt(Math.random() * list.length)];
        }

        return server + ""; // string
    }

    // OSM use up to 3 or 4 servers: "a", "b", "c", "d"
    // default is 3 servers

    function randomServerOSM(number) {
        var tile_servers = ["a", "b", "c", "d"];
        var max = 3;
        if (max > tile_servers.length) max = tile_servers.length;

        if (!number || number > tile_servers.length || number < 0) number = max;

        var data = [];
        for (var i = 0; i < number; i++) {
            data.push(tile_servers[i]);
        }

        return randomServer(data);
    }

    //
    // Bing normal map:
    // http://ecn.t2.tiles.virtualearth.net/tiles/r1202102332222?g=681&mkt=de-de&lbl=l1&stl=h&shading=hill&n=z
    // http://ecn.t0.tiles.virtualearth.net/tiles/r12021023322300?g=681&mkt=de-de&lbl=l1&stl=h&shading=hill&n=z
    // 
    // Bird view:
    // http://ecn.t2.tiles.virtualearth.net/tiles/h120022.jpeg?g=681&mkt=en-gb&n=z
    // http://ecn.t0.tiles.virtualearth.net/tiles/cmd/ObliqueHybrid?a=12021023322-256-19-18&g=681
    //
    // http://rbrundritt.wordpress.com/2009/01/08/birds-eye-imagery-extraction-via-the-virtual-earth-web-services-part-2/
    //
    // map type: "r" (roadmap), "h" (hybrid", "a" (arial)

    function getTileUrlBingVirtualearth(a, z, type, lang) {
        var url;

        // low resolution, hybrid like map
        if (z <= 17) {
            url = "http://ecn.t" + randomServer(4) + ".tiles.virtualearth.net/tiles/" + type + getQuadKey(a, z);

            if (type == "r") {
                url += "?g=681&mkt=" + lang + "&lbl=l1&stl=h&shading=hill&n=z";
            } else if (type == "h" || type == "a") {
                url += ".jpeg?g=681&mkt=" + lang + "&n=z";
            }

            // Bird view
        } else {
            url = "http://ecn.t" + randomServer(4) + ".tiles.virtualearth.net/tiles/cmd/ObliqueHybrid?" + type + "=" + getQuadKey(a, z);
            url += "-256-19-18" + "&g=681";
        }

        return url + "&zoom=" + z;
    }

    // Converts tile XY coordinates into a QuadKey at a specified level of detail.
    // http://msdn.microsoft.com/en-us/library/bb259689.aspx

    function getQuadKey(a, z) {
        var quadKey = "";

        // bing quadKey does work only up to level of 17
        // http://rbrundritt.wordpress.com/2009/01/08/birds-eye-imagery-extraction-via-the-virtual-earth-web-services-part-1/
        var zReal = z;
        if (z > 17) z = 17;

        for (var i = z; i > 0; i--) {
            var digit = '0';
            var mask = 1 << (i - 1);

            if ((a.x & mask) != 0) {
                digit++;
            }

            if ((a.y & mask) != 0) {
                digit++;
                digit++;
            }
            quadKey += digit;
        }

        return quadKey;
    }

    var bing_birdview_options = {
        bbbike: {
            "name": "Bing Sat",
            "description": "Bing Satellite and Bird View, by Microsoft"
        },
        getTileUrl: function (a, z) {
            return getTileUrlBingVirtualearth(a, z, "a", lang);
        },
        isPng: false,
        opacity: 1.0,
        tileSize: new google.maps.Size(256, 256),
        name: "BING-BIRDVIEW",
        minZoom: 1,
        maxZoom: 18 // 23
    };

    function nokia(a, z, name, servers) {
        // [http://4.maptile.lbs.ovi.com/maptiler/v2/maptile/a2e328a0c5/normal.day/${z}/${x}/${y}/256/png8?app_id=SqE1xcSngCd3m4a1zEGb&token=r0sR1DzqDkS6sDnh902FWQ&lg=ENG"]
        var app_id = "SqE1xcSngCd3m4a1zEGb";
        var token = "r0sR1DzqDkS6sDnh902FWQ&lg";
        var tile_id = "f8c7b21875";

        if (!servers || servers.length == 0) {
            servers = ["1", "2", "3", "4"];
        }

        var urls = {
            "normal.day": "base.maps.api.here.com/maptile/2.1/maptile/" + tile_id,
            "terrain.day": "aerial.maps.api.here.com/maptile/2.1/maptile/" + tile_id,
            "satellite.day": "aerial.maps.api.here.com/maptile/2.1/maptile/" + tile_id,
            "hybrid.day": "aerial.maps.api.here.com/maptile/2.1/maptile/" + tile_id,
            "normal.day.transit": "base.maps.api.here.com/maptile/2.1/maptile/" + tile_id,
            "newest/normal.day": "traffic.maps.api.here.com/maptile/2.1/" + "traffictile"
        };
        var url_prefix = urls[name];

        var url = "http://" + randomServer(servers) + "." + url_prefix + "/" + name + "/" + z + "/" + a.x + "/" + a.y + "/256/png8?app_id=" + app_id + "&token=" + token + "lg=ENG";

        return url;
    }

    var mapControls = {
        "mapnik": function () {
            if (bbbike.mapType.MapnikMapType) {
                var MapnikMapType = new google.maps.ImageMapType(mapnik_options);
                map.mapTypes.set("mapnik", MapnikMapType);
                custom_map("mapnik", lang, mapnik_options.bbbike);
            }
        },
        "mapnik_de": function () {
            if (bbbike.mapType.MapnikDeMapType && is_european(region)) {
                var MapnikDeMapType = new google.maps.ImageMapType(mapnik_de_options);
                map.mapTypes.set("mapnik_de", MapnikDeMapType);
                custom_map("mapnik_de", lang, mapnik_de_options.bbbike);
            }
        },
        "bbbike_mapnik": function () {
            if (bbbike.mapType.BBBikeMapnikMapType && (city == "bbbike" || city == "Berlin")) {
                //bbbike.mapDefault = "bbbike_mapnik"; // make it the default map
                var BBBikeMapnikMapType = new google.maps.ImageMapType(bbbike_mapnik_options);
                map.mapTypes.set("bbbike_mapnik", BBBikeMapnikMapType);
                custom_map("bbbike_mapnik", lang, bbbike_mapnik_options.bbbike);
            }
        },


        "bbbike_mapnik_german": function () {
            if (bbbike.mapType.BBBikeMapnikGermanMapType && (city == "bbbike" || city == "Berlin")) {
                var BBBikeMapnikGermanMapType = new google.maps.ImageMapType(bbbike_mapnik_german_options);
                map.mapTypes.set("bbbike_mapnik_german", BBBikeMapnikGermanMapType);
                custom_map("bbbike_mapnik_german", lang, bbbike_mapnik_german_options.bbbike);
            }
        },
        "mapnik_bw": function () {
            if (bbbike.mapType.MapnikBwMapType) {
                var MapnikBwMapType = new google.maps.ImageMapType(mapnik_bw_options);
                map.mapTypes.set("mapnik_bw", MapnikBwMapType);
                custom_map("mapnik_bw", lang, mapnik_bw_options.bbbike);
            }
        },

        "cycle": function () {
            if (bbbike.mapType.CycleMapType) {
                var CycleMapType = new google.maps.ImageMapType(cycle_options);
                map.mapTypes.set("cycle", CycleMapType);
                custom_map("cycle", lang, cycle_options.bbbike);
            }
        },

        "hike_bike": function () {
            if (bbbike.mapType.HikeBikeMapType) {
                var HikeBikeMapType = new google.maps.ImageMapType(hike_bike_options);
                map.mapTypes.set("hike_bike", HikeBikeMapType);
                custom_map("hike_bike", lang, hike_bike_options.bbbike);
            }
        },

        "public_transport": function () {
            if (bbbike.mapType.PublicTransportMapType && is_european(region)) {
                var PublicTransportMapType = new google.maps.ImageMapType(public_transport_options);
                map.mapTypes.set("public_transport", PublicTransportMapType);
                custom_map("public_transport", lang, public_transport_options.bbbike);
            }
        },

        "ocm_transport": function () {
            if (bbbike.mapType.OCMTransport) {
                var OCMTransportMapType = new google.maps.ImageMapType(ocm_transport_options);
                map.mapTypes.set("ocm_transport", OCMTransportMapType);
                custom_map("ocm_transport", lang, ocm_transport_options.bbbike);
            }
        },

        "ocm_landscape": function () {
            if (bbbike.mapType.OCMLandscape) {
                var OCMLandscapeMapType = new google.maps.ImageMapType(ocm_landscape_options);
                map.mapTypes.set("ocm_landscape", OCMLandscapeMapType);
                custom_map("ocm_landscape", lang, ocm_landscape_options.bbbike);
            }
        },

        "yahoo_map": function () {
            if (bbbike.mapType.YahooMapMapType) {
                var YahooMapMapType = new google.maps.ImageMapType(yahoo_map_options);
                map.mapTypes.set("yahoo_map", YahooMapMapType);
                custom_map("yahoo_map", lang, yahoo_map_options.bbbike);
            }
        },
        "yahoo_satellite": function () {
            if (bbbike.mapType.YahooSatelliteMapType) {
                var YahooSatelliteMapType = new google.maps.ImageMapType(yahoo_satellite_options);
                map.mapTypes.set("yahoo_satellite", YahooSatelliteMapType);
                custom_map("yahoo_satellite", lang, yahoo_satellite_options.bbbike);
            }
        },
        "yahoo_hybrid": function () {
            if (bbbike.mapType.YahooHybridMapType) {
                var YahooHybridMapType = new google.maps.ImageMapType(yahoo_hybrid_options);
                map.mapTypes.set("yahoo_hybrid", YahooHybridMapType);
                custom_map("yahoo_hybrid", lang, yahoo_hybrid_options.bbbike);
            }
        },

        "bing_map_old": function () {
            if (bbbike.mapType.BingMapOldMapType) {
                var BingMapMapType = new google.maps.ImageMapType(bing_map_old_options);
                map.mapTypes.set("bing_map_old", BingMapMapType);
                custom_map("bing_map_old", lang, bing_map_old_options.bbbike);
            }
        },
        "bing_map": function () {
            if (bbbike.mapType.BingMapMapType) {
                var BingMapMapType = new google.maps.ImageMapType(bing_map_options);
                map.mapTypes.set("bing_map", BingMapMapType);
                custom_map("bing_map", lang, bing_map_options.bbbike);
            }
        },
        "bing_satellite": function () {
            if (bbbike.mapType.BingSatelliteMapType) {
                var BingSatelliteMapType = new google.maps.ImageMapType(bing_satellite_options);
                map.mapTypes.set("bing_satellite", BingSatelliteMapType);
                custom_map("bing_satellite", lang, bing_satellite_options.bbbike);
            }
        },
        "bing_birdview": function () {
            if (bbbike.mapType.BingBirdviewMapType) {
                var BingBirdviewMapType = new google.maps.ImageMapType(bing_birdview_options);
                map.mapTypes.set("bing_birdview", BingBirdviewMapType);
                custom_map("bing_birdview", lang, bing_birdview_options.bbbike);
            }
        },
        "bing_hybrid": function () {
            if (bbbike.mapType.BingHybridMapType) {
                var BingHybridMapType = new google.maps.ImageMapType(bing_hybrid_options);
                map.mapTypes.set("bing_hybrid", BingHybridMapType);
                custom_map("bing_hybrid", lang, bing_hybrid_options.bbbike);
            }
        },
        "mapquest": function () {
            if (bbbike.mapType.MapQuest) {
                var MapQuestMapType = new google.maps.ImageMapType(mapquest_options);
                map.mapTypes.set("mapquest", MapQuestMapType);
                custom_map("mapquest", lang, mapquest_options.bbbike);
            }
        },
        "mapquest_satellite": function () {
            if (bbbike.mapType.MapQuestSatellite) {
                var MapQuestSatelliteMapType = new google.maps.ImageMapType(mapquest_satellite_options);
                map.mapTypes.set("mapquest_satellite", MapQuestSatelliteMapType);
                custom_map("mapquest_satellite", lang, mapquest_satellite_options.bbbike);
            }
        },
        "esri": function () {
            if (bbbike.mapType.Esri) {
                var EsriMapType = new google.maps.ImageMapType(esri_options);
                map.mapTypes.set("esri", EsriMapType);
                custom_map("esri", lang, esri_options.bbbike);
            }
        },
        "esri_topo": function () {
            if (bbbike.mapType.EsriTopo) {
                var EsriTopoMapType = new google.maps.ImageMapType(esri_topo_options);
                map.mapTypes.set("esri_topo", EsriTopoMapType);
                custom_map("esri_topo", lang, esri_topo_options.bbbike);
            }
        },
        "mapbox": function () {
            if (bbbike.mapType.MapBox) {
                var MapBoxMapType = new google.maps.ImageMapType(mapbox_options);
                map.mapTypes.set("mapbox", MapBoxMapType);
                custom_map("mapbox", lang, mapbox_options.bbbike);
            }
        },
        "toner": function () {
            if (bbbike.mapType.Toner) {
                var TonerType = new google.maps.ImageMapType(toner_options);
                map.mapTypes.set("toner", TonerType);
                custom_map("toner", lang, toner_options.bbbike);
            }
        },
        "watercolor": function () {
            if (bbbike.mapType.Watercolor) {
                var WatercolorType = new google.maps.ImageMapType(watercolor_options);
                map.mapTypes.set("watercolor", WatercolorType);
                custom_map("watercolor", lang, watercolor_options.bbbike);
            }
        },
        "nokia_traffic": function () {
            if (bbbike.mapType.NokiaTraffic) {
                var NokiaTrafficType = new google.maps.ImageMapType(nokia_traffic_options);
                map.mapTypes.set("nokia_traffic", NokiaTrafficType);
                custom_map("nokia_traffic", lang, nokia_traffic_options.bbbike);
            }
        },
        "apple": function () {
            if (bbbike.mapType.Apple) {
                var AppleMapType = new google.maps.ImageMapType(apple_options);
                map.mapTypes.set("apple", AppleMapType);
                custom_map("apple", lang, apple_options.bbbike);
            }
        }
        // trailing comma for IE6
    };

    // custome layer
    var mapLayers = {
        "bbbike_smoothness": function () {
            if (bbbike.mapLayers.Smoothness) {
                return new google.maps.ImageMapType(bbbike_smoothness_options);
            }
        },
        "velo_layer": function () {
            if (bbbike.mapLayers.VeloLayer) {
                return new google.maps.ImageMapType(velo_layer_options);
            }
        },
        "max_speed": function () {
            if (bbbike.mapLayers.MaxSpeed) {
                return new google.maps.ImageMapType(max_speed_options);
            }
        },
        "land_shading": function () {
            if (bbbike.mapLayers.LandShading) {
                return new google.maps.ImageMapType(land_shading_options);
            }
        },
    };

    // keep in order for slide show
    // top postion
    mapControls.bbbike_mapnik();
    mapControls.bbbike_mapnik_german();
    mapControls.mapnik();
    mapControls.mapnik_de();
    mapControls.cycle();
    mapControls.hike_bike();
    mapControls.public_transport();
    mapControls.ocm_transport();
    mapControls.ocm_landscape();
    mapControls.esri();
    mapControls.esri_topo();
    mapControls.mapbox();
    mapControls.apple();

    // bottom postion
    mapControls.mapnik_bw();
    mapControls.toner();
    mapControls.watercolor();
    mapControls.nokia_traffic();
    mapControls.bing_map();
    mapControls.bing_map_old();
    mapControls.yahoo_map();
    mapControls.mapquest();
    mapControls.mapquest_satellite();
    mapControls.bing_satellite();
    mapControls.bing_birdview();
    mapControls.yahoo_satellite();
    mapControls.bing_hybrid();
    mapControls.yahoo_hybrid();

    map.setMapTypeId(maptype);
    if (is_supported_maptype(maptype, bbbike.available_custom_maps)) {
        setCustomBold(maptype);
    }

    // maps layers
    init_google_layers(layer);
    init_custom_layers(mapLayers, layer);

    if (bbbike.mapLayers.Smoothness && (city == "bbbike" || city == "Berlin" || city == "Oranienburg" || city == "Potsdam" || city == "FrankfurtOder")) {
        custom_layer(map, {
            "id": "bbbike_smoothness",
            "layer": "Smoothness",
            "enabled": bbbike.mapLayers.Smoothness,
            "active": layer == "smoothness" ? true : false,
            "callback": add_smoothness_layer,
            "lang": lang
        });
    }

    if (bbbike.mapLayers.VeloLayer && is_european(region)) {
        custom_layer(map, {
            "id": "velo_layer",
            "layer": "VeloLayer",
            "enabled": bbbike.mapLayers.VeloLayer,
            "active": layer == "velo_layer" ? true : false,
            "callback": add_velo_layer,
            "lang": lang
        });
    }

    if (bbbike.mapLayers.MaxSpeed && is_european(region)) {
        custom_layer(map, {
            "id": "max_speed",
            "layer": "MaxSpeed",
            "enabled": bbbike.mapLayers.MaxSpeed,
            "active": layer == "max_speed" ? true : false,
            "callback": add_max_speed_layer,
            "lang": lang
        });
    }

    custom_layer(map, {
        "id": "land_shading",
        "layer": "Land Shading",
        "enabled": bbbike.mapLayers.LandShading,
        "active": layer == "land_shading" ? true : false,
        "callback": add_land_shading_layer,
        "lang": lang
    });



    custom_layer(map, {
        "id": "google_PanoramioLayer",
        "layer": "PanoramioLayer",
        "enabled": bbbike.mapLayers.PanoramioLayer,
        "active": layer == "panoramio" ? true : false,
        "callback": add_panoramio_layer,
        "lang": lang
    });

    custom_layer(map, {
        "id": "google_WeatherLayer",
        "layer": "WeatherLayer",
        "enabled": bbbike.mapLayers.WeatherLayer,
        "active": layer == "weather" ? true : false,
        "callback": add_weather_layer,
        "lang": lang
    });

    custom_layer(map, {
        "layer": "SlideShow",
        "enabled": bbbike.mapLayers.SlideShow,
        "active": layer == "slideshow" ? true : false,
        "callback": runSlideShow,
        "lang": lang
    });

    custom_layer(map, {
        "layer": "FullScreen",
        "enabled": bbbike.mapLayers.FullScreen,
        "active": layer == "fullscreen" ? true : false,
        "callback": toogleFullScreen,
        "lang": lang
    });

    custom_layer(map, {
        "layer": "Replay",
        "enabled": bbbike.mapLayers.Replay && is_route,
        // display only on route result page
        "active": layer == "replay" ? true : false,
        "callback": runReplay,
        "lang": lang
    });

    custom_layer(map, {
        "id": "google_BicyclingLayer",
        "layer": "BicyclingLayer",
        "enabled": bbbike.mapLayers.BicyclingLayer,
        "active": layer == "bicycling" ? true : false,
        "callback": add_bicycle_layer,
        "lang": lang
    });

    custom_layer(map, {
        "id": "google_TrafficLayer",
        "layer": "TrafficLayer",
        "enabled": bbbike.mapLayers.TrafficLayer,
        "active": layer == "traffic" ? true : false,
        "callback": add_traffic_layer,
        "lang": lang
    });

    setTimeout(function () {
        hideGoogleLayers(maptype);
    }, 300); // fast CPU
    setTimeout(function () {
        hideGoogleLayers(maptype);
    }, 1000);
    // setTimeout(function () { hideGoogleLayers(); }, 2000);
    // enable Google Arial View
    if (bbbike.mapImagery45 > 0) {
        map.setTilt(bbbike.mapImagery45);
    }

    // map changed
    google.maps.event.addListener(map, "maptypeid_changed", function () {
        hideGoogleLayers();
    });

    google.maps.event.clearListeners(map, 'rightclick');
    google.maps.event.addListener(map, "rightclick", function (event) {
        var zoom = map.getZoom();

        // Firefox 4.x and later bug
        (function (zoom) {
            var timeout = 10;
            var timer = setTimeout(function () {
                var z = map.getZoom();
                if (z + 1 == zoom) {
                    map.setZoom(zoom);
                    debug("reset zoom level to: " + zoom);
                }
            }, timeout);
        })(zoom);

        // on start page only
        if (state.markers.marker_start) debug("rightclick " + zoom + " " + pixelPos(event));

    });

    setTimeout(function () {
        setMapHeight();
    }, 200);
}

function pixelPos(event) {

    var topRight = map.getProjection().fromLatLngToPoint(map.getBounds().getNorthEast());
    var bottomLeft = map.getProjection().fromLatLngToPoint(map.getBounds().getSouthWest());
    var scale = Math.pow(2, map.getZoom());
    // var worldPoint=map.getProjection().fromLatLngToPoint(marker.getPosition());
    var worldPoint = map.getProjection().fromLatLngToPoint(event.latLng);

    var point = new google.maps.Point((worldPoint.x - bottomLeft.x) * scale, (worldPoint.y - topRight.y) * scale);

    var map_div = document.getElementById("map");
    var menu_div = document.getElementById("start_menu");

    // create start menu
    if (!menu_div) {
        menu_div = document.createElement('div');

        menu_div.style.padding = '8px';
        menu_div.style.margin = '2px';

        // Set CSS for the control border
        menu_div.style.backgroundColor = 'white';
        menu_div.style.borderStyle = 'solid';
        menu_div.style.borderWidth = '0px';
        // menu_div.style.cursor = 'pointer';
        menu_div.style.textAlign = 'center';

        menu_div.id = "start_menu";
        menu_div.style.position = "absolute";

        map_div.appendChild(menu_div);
    }

    menu_div.style.display = "block";
    // setTimeout(function () { menu_div.style.display = "none";}, 8000);
    menu_div.style.left = point.x + "px";
    menu_div.style.top = point.y + "px";

    var content = ""; // "foobar " + "x: " + point.x + "y: " + point.y + "<br/>\n";
    // var pos = marker.getPosition();
    var type = ["start", "via", "ziel"];
    var address = "";

    for (var i = 0; i < type.length; i++) {
        if (i > 0) content += " | ";
        content += "<a href='#' onclick='javascript:setMarker(\"" + type[i] + '", "' + address + '", ' + granularity(event.latLng.lat()) + ", " + granularity(event.latLng.lng()) + ', "start_menu"' + ");'>" + translate_mapcontrol(type[i]) + "</a>" + "\n";
    }

    menu_div.innerHTML = content;

    if (state.timeout_menu) clearTimeout(state.timeout_menu);
    google.maps.event.addDomListenerOnce(menu_div, 'mouseout', function () {
        debug("got mouseout");
        state.timeout_menu = setTimeout(function () {
            menu_div.style.display = "none";
        }, 6000);
    });

    return "x: " + point.x + "y: " + point.y;
}



// layers which works only on google maps

function init_google_layers() {
    try {
        layers.bicyclingLayer = new google.maps.BicyclingLayer();
        layers.trafficLayer = new google.maps.TrafficLayer();
        layers.weatherLayer = new google.maps.weather.WeatherLayer();
    } catch (e) {}

    // need to download library first
    layers.panoramioLayer = false;
}

// custom layers

function init_custom_layers(layer) {
    if (bbbike.mapLayers.Smoothness) {
        layers.smoothnessLayer = layer.bbbike_smoothness();
    }
    if (bbbike.mapLayers.LandShading) {
        layers.land_shadingLayer = layer.land_shading();
    }
    if (bbbike.mapLayers.VeloLayer) {
        layers.veloLayer = layer.velo_layer();
    }
    if (bbbike.mapLayers.MaxSpeed) {
        layers.maxSpeedLayer = layer.max_speed();
    }
}


function debug_layer(layer) {
    var data = layer;
    for (var l in layerControl) {
        data += " " + l + ": " + layerControl[l];
    }

    debug(data);
}

// add bicycle routes and lanes to map, by google maps

function add_bicycle_layer(map, enable) {
    if (!layers.bicyclingLayer) return;

    if (enable) {
        layers.bicyclingLayer.setMap(map);
    } else {
        layers.bicyclingLayer.setMap(null);
    }
}

function add_weather_layer(map, enable) {
    if (!layers.weatherLayer) return;

    if (enable) {
        layers.weatherLayer.setMap(map);
    } else {
        layers.weatherLayer.setMap(null);
    }
}

// add traffic to map, by google maps

function add_traffic_layer(map, enable) {
    if (!layers.trafficLayer) return;

    if (enable) {
        layers.trafficLayer.setMap(map);
    } else {
        layers.trafficLayer.setMap(null);
    }
}

// bbbike smoothness layer

function add_smoothness_layer(map, enable) {
    if (!layers.smoothnessLayer) return;

    if (enable) {
        map.overlayMapTypes.setAt(0, layers.smoothnessLayer);
    } else {
        map.overlayMapTypes.setAt(0, null);
    }
}

function add_velo_layer(map, enable) {
    if (!layers.veloLayer) return;

    if (enable) {
        map.overlayMapTypes.setAt(1, layers.veloLayer);
    } else {
        map.overlayMapTypes.setAt(1, null);
    }
}

function add_max_speed_layer(map, enable) {
    if (!layers.maxSpeedLayer) return;

    if (enable) {
        map.overlayMapTypes.setAt(2, layers.maxSpeedLayer);
    } else {
        map.overlayMapTypes.setAt(2, null);
    }
}

function add_land_shading_layer(map, enable) {
    debug_layer("shading");

    if (!layers.land_shadingLayer) return;

    if (enable) {
        map.overlayMapTypes.setAt(3, layers.land_shadingLayer);
    } else {
        map.overlayMapTypes.setAt(3, null);
    }
}

// add traffic to map, by google maps

function add_panoramio_layer(map, enable) {
    // ignore if nothing to display
    if (!layers.panoramioLayer && !enable) return;

    //  activate library for panoramio
    if (!layers.panoramioLayer) {
        layers.panoramioLayer = new google.maps.panoramio.PanoramioLayer();
    }

    layers.panoramioLayer.setMap(enable ? map : null);
}

//
// guess if a streetname is from the OSM database
// false: 123,456
// false: foo [123,456]
//

function osm_streetname(street) {
    if (street.match(/^[\-\+ ]?[0-9\.]+,[\-\+ ]?[0-9\.]+[ ]*$/) || street.match(/^.* \[[0-9\.,\-\+]+\][ ]*$/)) {
        return 0;
    } else {
        return 1;
    }
}

function plotStreetGPS(street, caller) {
    var pos = street.match(/^(.*) \[([0-9\.,\-\+]+),[0-9]\][ ]*$/);

    debug("pos: " + pos[1] + " :: " + pos[2] + " :: length: " + pos.length);
    if (pos.length == 3) {
        var data = '["' + pos[1] + '",["' + pos[1] + "\t" + pos[2] + '"]]';
        debug(data);

        // plotStreet()
        caller(data);
    } else {
        debug("cannot plot street");
    }
}

var street = "";
var street_cache = [];
var data_cache = [];


function setMarker(type, address, lat, lng, div) {
    var marker = state.markers["marker_" + type];
    if (type == "via") displayVia();

    var id = "suggest_" + type;
    marker.setPosition(new google.maps.LatLng(lat, lng));

    // no address - look in database
    if (!address || address == "") {
        find_street(marker, id);

        // hide div after we move a marker
        if (div) {
            var tag = document.getElementById(div);
            if (tag) tag.style.display = "none";
        }
    }

    // address is known, fake resonse
    else {

        // find_street(marker, "suggest_" + type, null);
        // { query:"7.44007,46.93205", suggestions:["7.44042,46.93287     Bondelistr./"] }
        var data = '{query:"' + lng + "," + lat + '", suggestions:["' + lng + "," + lat + "\t" + address + '"]}';
        updateCrossing(marker, id, data);
        debug("data: " + data);
    }
}

function getStreet(map, city, street, strokeColor, noCleanup) {
    var streetnames = 3; // if set, display a info window with the street name
    var autozoom = 13; // if set, zoom to the streets
    var url = encodeURI("/cgi/street-coord.cgi?namespace=" + (streetnames ? "3" : "0") + ";city=" + city + "&query=" + street);

    if (!osm_streetname(street)) {
        debug("Not a OSM street name: '" + street + ', skip ajax call"');
        return plotStreetGPS(street, plotStreet);
    }

    if (!strokeColor) {
        strokeColor = "#0000FF";
    }

    if (!noCleanup) {
        // cleanup map
        for (var i = 0; i < street_cache.length; i++) {
            street_cache[i].setMap(null);
        }
        street_cache = [];
    }

    // read data from cache
    if (data_cache[url] != undefined) {
        return plotStreet(data_cache[url]);
    }



    function addInfoWindowStreet(marker, address, pos) {
        var infoWindow = new google.maps.InfoWindow({
            maxWidth: 500
        });

        // var pos = marker.getPosition();
        var type = ["start", "via", "ziel"];

        var content = "<span id=\"infoWindowContent\">\n"
        content += "<p>" + address + "</p>\n";
        for (var i = 0; i < type.length; i++) {
            if (i > 0) content += " | ";
            content += "<a href='#' onclick='javascript:setMarker(\"" + type[i] + '", "' + address + '", ' + granularity(pos.lat()) + ", " + granularity(pos.lng()) + ");'>" + translate_mapcontrol(type[i]) + "</a>" + "\n";
        }

        content += "</span>\n";
        infoWindow.setContent(content);
        infoWindow.open(map, marker);

        // close info window after 4 seconds
        setTimeout(function () {
            infoWindow.close()
        }, 5000)

    };

    // plot street(s) on map

    function plotStreet(data) {
        var js = eval(data);
        var streets_list = js[1];
        var query = js[0];
        var query_lc = query.toLowerCase();

        var autozoom_points = [];
        for (var i = 0; i < streets_list.length; i++) {
            var streets_route = new Array;
            var s;
            var street;

            if (!streetnames) {
                s = streets_list[i].split(" ");
            } else {
                var list = streets_list[i].split("\t");
                street = list[0];
                s = list[1].split(" ");
            }

            for (var j = 0; j < s.length; j++) {
                var coords = s[j].split(",");
                streets_route.push(new google.maps.LatLng(coords[1], coords[0]));
            }

            // only a point, create a list
            if (streets_route.length == 1) {
                streets_route[1] = streets_route[0];
            }

            var route = new google.maps.Polyline({
                path: streets_route,
                strokeColor: strokeColor,
                strokeWeight: 7,
                strokeOpacity: 0.5
            });
            route.setMap(map);

            street_cache.push(route);

            if (autozoom) {
                autozoom_points.push(streets_route[0]);
                autozoom_points.push(streets_route[streets_route.length - 1]);
            }

            // display a small marker for every street
            if (streetnames) {
                var pos = 0;
                // set the marker in the middle of the street
                if (streets_route.length > 0) {
                    pos = Math.ceil((streets_route.length - 1) / 2);
                }

                var marker = new google.maps.Marker({
                    position: streets_route[pos],
                    icon: query_lc == street.toLowerCase() ? bbbike.icons.green : bbbike.icons.white,
                    map: map
                });

                google.maps.event.addListener(marker, "click", function (marker, street, position) {
                    return function (event) {
                        addInfoWindowStreet(marker, street, position);
                    }
                }(marker, street, streets_route[pos]));

                if (streets_list.length <= 10) {
                    addInfoWindowStreet(marker, street, streets_route[pos]);
                }

                street_cache.push(marker);

            }

        }

        if (autozoom && autozoom_points.length > 0) {
            // improve zoom level, max. area as possible
            var bounds = new google.maps.LatLngBounds;
            for (var i = 0; i < autozoom_points.length; i++) {
                bounds.extend(autozoom_points[i]);
            }
            map.fitBounds(bounds);
            var zoom = map.getZoom();
            // do not zoom higher than XY
            map.setZoom(zoom > autozoom ? autozoom : zoom);
            // alert("zoom: " + zoom);
        }
    }

    // download street coords with AJAX
    downloadUrl(url, function (data, responseCode) {
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
var infoWindow;
var routeSave;
var _area_hash = [];

function plotRoute(map, opt, street) {
    var r = [];

    for (var i = 0; i < street.length; i++) {
        //  string: '23.3529099,42.6708386'
        if (typeof street[i] == 'string') {
            var coords = street[i].split(",");
            r.push(new google.maps.LatLng(coords[1], coords[0]));
        }

        // array: [lat,lng] 
        else {
            r.push(new google.maps.LatLng(street[i][1], street[i][0]));
        }
    }

    // create a random color
    var color; {
        var _color_r = parseInt(Math.random() * 16).toString(16);
        var _color_g = parseInt(Math.random() * 16).toString(16);
        var _color_b = parseInt(Math.random() * 16).toString(16);

        color = "#" + _color_r + _color_r + _color_g + _color_g + _color_b + _color_b;
    }

    var x = r.length > 8 ? 8 : r.length;
    var route = new google.maps.Polyline({
        clickable: true,
        path: r,
        strokeColor: color,
        strokeWeight: 5,
        strokeOpacity: 0.5
    });
    route.setMap(map);

    var marker = new google.maps.Marker({
        position: r[parseInt(Math.random() * x)],
        icon: bbbike.icons.green,
        map: map
    });
    var marker2 = new google.maps.Marker({
        position: r[r.length - 1],
        icon: bbbike.icons.red,
        map: map
    });

    google.maps.event.addListener(marker, "click", function (event) {
        addInfoWindow(marker)
    });
    google.maps.event.addListener(marker2, "click", function (event) {
        addInfoWindow(marker2)
    });

    if (opt.viac && opt.viac != "") {
        var coords = opt.viac.split(",");
        var pos = new google.maps.LatLng(coords[1], coords[0]);

        var marker3 = new google.maps.Marker({
            position: pos,
            icon: bbbike.icons.yellow,
            map: map
        });
        google.maps.event.addListener(marker3, "click", function (event) {
            addInfoWindow(marker3)
        });
    }

    function driving_time(driving_time) {
        var data = "";
        var time = driving_time.split('|');
        for (var i = 0; i < time.length; i++) {
            var t = time[i].split(':');
            data += t[0] + ":" + t[1] + "h (at " + t[2] + "km/h) ";
        }
        return data;
    }

    function area(area) {
        var a = area.split("!");
        var x1y1 = a[0].split(",");
        var x2y2 = a[1].split(",");
        var x1 = x1y1[1];
        var y1 = x1y1[0];
        var x2 = x2y2[1];
        var y2 = x2y2[0];

        var r = [];
        r.push(new google.maps.LatLng(x1, y1));
        r.push(new google.maps.LatLng(x1, y2));
        r.push(new google.maps.LatLng(x2, y2));
        r.push(new google.maps.LatLng(x2, y1));
        r.push(new google.maps.LatLng(x1, y1));

        var route = new google.maps.Polyline({
            path: r,
            strokeColor: "#006400",
            strokeWeight: 4,
            strokeOpacity: 0.5
        });
        route.setMap(map);
    }

    // plot the area *once* for a city
    if (opt.area && !_area_hash[opt.area]) {
        area(opt.area);
        _area_hash[opt.area] = 1;
    }


    function addInfoWindow(marker) {
        var icons = [bbbike.icons.green, bbbike.icons.red, bbbike.icons.yellow];

        if (infoWindow) {
            infoWindow.close();
        }
        if (routeSave) {
            routeSave.setOptions({
                strokeWeight: 5
            });
        }

        infoWindow = new google.maps.InfoWindow({
            maxWidth: 400
        });
        var content = "<div id=\"infoWindowContent\">\n"
        content += "City: " + '<a target="_new" href="/' + opt.city + '/">' + opt.city + '</a>' + "<br/>\n";
        content += "<img height='12' src='" + icons[0] + "' /> " + "Start: " + opt.startname + "<br/>\n";
        if (opt.vianame && opt.vianame != "") {
            content += "<img height='12' src='" + icons[2] + "' /> " + "Via: " + opt.vianame + "<br/>\n";
        }
        content += "<img height='12' src='" + icons[1] + "' /> " + "Destination: " + opt.zielname + "<br/>\n";
        content += "Route Length: " + opt.route_length + "km<br/>\n";

        if (opt.driving_time) {
            content += "Driving time: " + driving_time(opt.driving_time) + "<br/>\n";
        }

        // pref_cat pref_quality pref_specialvehicle pref_speed pref_ferry pref_unlit
        if (opt.pref_speed != "" && opt.pref_speed != "20") {
            content += "Preferred speed: " + opt.pref_speed + "<br/>\n";
        }
        if (opt.pref_cat != "") {
            content += "Preferred street category: " + opt.pref_cat + "<br/>\n";
        }
        if (opt.pref_quality != "") {
            content += "Road surface: " + opt.pref_quality + "<br/>\n";
        }
        if (opt.pref_unlit != "") {
            content += "Avoid unlit streets: " + opt.pref_unlit + "<br/>\n";
        }
        if (opt.pref_specialvehicle != "") {
            content += "On the way with: " + opt.pref_specialvehicle + "<br/>\n";
        }
        if (opt.pref_ferry != "") {
            content += "Use ferries: " + opt.pref_ferry + "<br/>\n";
        }

        content += "</div>\n";
        infoWindow.setContent(content);
        infoWindow.open(map, marker);


        routeSave = route;
        route.setOptions({
            strokeWeight: 10
        });
    };
}

// bbbike_maps_init("default", [[48.0500000,7.3100000],[48.1300000,7.4100000]] );
// localized custom map names

function translate_mapcontrol(word, lang) {
    if (!lang) {
        lang = state.lang;
    }

    var l = {
        // master language, fallback for all
        "en": {
            "mapnik": "Mapnik",
            "cycle": "Cycle",
            "hike_bike": "Hike&amp;Bike",
            "public_transport": "Public Transport",
            "mapnik_de": "Mapnik (de)",
            "mapnik_bw": "Mapnik (b/w)",
            "yahoo_map": "Yahoo",
            "mapquest": "MapQuest",
            "mapquest_satellite": "MapQuest (Sat)",
            "yahoo_hybrid": "Yahoo (hybrid)",
            "yahoo_satellite": "Yahoo (Sat)",
            "bing_map": "Bing",
            "bing_map_old": "Bing (old)",
            "bing_satellite": "Bing Sat",
            "bing_hybrid": "Bing Hybrid",
            "FullScreen": "Fullscreen",
            "Replay": "Replay",
            "SlideShow": "Slide Show",
            "esri": "Esri",
            "esri_topo": "Esri Topo",
            "mapbox": "MapBox",
            "apple": "Apple",
            "VeloLayer": "Velo-Layer",
            "MaxSpeed": "Speed Limit",
            "WeatherLayer": "Weather",
            "BicyclingLayer": "Google Bicyling",
            "TrafficLayer": "Google Traffic",
            "PanoramioLayer": "Panoramio",
            "toner": "Toner",
            "watercolor": "Watercolor",
            "NokiaTraffic": "Here Traffic",

            "start": "Start",
            "ziel": "Destination",
            "via": "Via",

            "bing_birdview": "Bing Sat" // last 
        },

        // rest
        "da": {
            "cycle": "Cykel"
        },
        "de": {
            "Mapnik": "Mapnik",
            "Cycle": "Fahrrad",
            "traffic layer": "Google Verkehr",
            "Panoramio": "Panoramio Fotos",
            "cycle layer": "Google Fahrrad",
            "Hike&Bike": "Wandern",
            "Landscape": "Landschaft",
            "Public Transport": "ÖPNV",
            'Show map': "Zeige Karte",
            "FullScreen": "Vollbildmodus",
            "Mapnik (b/w)": "Mapnik (s/w)",
            "Black/White Mapnik, by OpenStreetMap": "Schwarz/Weiss Mapnik, von OpenStreetMap",
            "Cycle, by OpenStreetMap": "Fahrrad, von OpenStreetMap",
            "Public Transport, by OpenStreetMap": "Öffentlicher Personennahverkehr, von OpenStreetMap",
            "German Mapnik, by OpenStreetMap": "Mapnik in deutschem Kartenlayout, von OpenStreetMap",
            "SlideShow": "Slideshow",
            "BicyclingLayer": "Google Fahrrad",
            "TrafficLayer": "Google Verkehr",

            "bing_birdview": "Bing Sat",
            "WeatherLayer": "Wetter",
            "NokiaTraffic": "Here Verkehr",

            "Set start point": "Setze Startpunkt",
            "Set destination point": "Setze Zielpunkt",
            "Set via point": "Setze Zwischenpunkt (Via)",
            "Your current postion": "Ihre aktuelle Position",
            "Approximate address": "Ungef&auml;hre Adresse",
            "crossing": "Kreuzung",
            "Error: outside area": "Fehler: ausserhalb des Gebietes",
            "Start": "Start",
            "Destination": "Ziel",
            "Smoothness": "Fahrbahnqualit&auml;t",
            "Land Shading": "Reliefkarte",
            "VeloLayer": "Velo-Layer",
            "MaxSpeed": "Tempo Limit",
            "Watercolor": "Aquarell",
            "Replay": "Replay",

            "start": "Start",
            "ziel": "Ziel",
            "via": "Via",

            "Via": "Via"
        },
        "es": {
            "cycle": "Bicicletas"
        },
        "fr": {
            "cycle": "Vélo"
        },
        "hr": {
            "cycle": "Bicikl"
        },
        "nl": {
            "cycle": "Fiets"
        },
        "pl": {
            "cycle": "Rower"
        },
        "pt": {
            "cycle": "Bicicleta"
        },
        "ru": {
            "cycle": "Велосипед"
        },
        "zh": {
            "cycle": "自行车"
        }
    };

    if (!lang) {
        return word;
    } else if (l[lang] && l[lang][word]) {
        return l[lang][word];
    } else if (l["en"] && l["en"][word]) {
        return l["en"][word];
    } else {
        return word;
    }
}




/**
 * The HomeControl adds a control to the map that simply
 * returns the user to Chicago. This constructor takes
 * the control DIV as an argument.
 */


function init_google_map_list() {
    var list = [];
    for (var i = 0; i < bbbike.mapTypeControlOptions.mapTypeIds.length; i++) {
        var maptype = bbbike.mapTypeControlOptions.mapTypeIds[i];
        list.push(maptype);
    }

    return list;
}

var currentText = {};

function HomeControl(controlDiv, map, maptype, lang, opt) {
    var name = opt && opt.name ? translate_mapcontrol(opt.name, lang) : translate_mapcontrol(maptype, lang);
    var description = opt && opt.description ? translate_mapcontrol(opt.description, lang) : translate_mapcontrol(maptype, lang);

    // Set CSS styles for the DIV containing the control
    // Setting padding to 5 px will offset the control
    // from the edge of the map
    var controlUI = document.createElement('DIV');
    var controlText = document.createElement('DIV');

    controlDiv.style.paddingTop = '5px';
    controlDiv.style.paddingRight = '2px';

    // Set CSS for the control border
    controlUI.style.backgroundColor = 'white';
    controlUI.style.borderStyle = 'solid';
    controlUI.style.borderWidth = '0px';
    controlUI.style.cursor = 'pointer';
    controlUI.style.textAlign = 'center';
    controlUI.title = translate_mapcontrol('Show map', lang) + " " + description;

    controlDiv.appendChild(controlUI);

    // Set CSS for the control interior
    // controlText.style.fontFamily = 'Arial,sans-serif';
    controlText.style.fontSize = '13px';
    controlText.style.paddingLeft = '8px';
    controlText.style.paddingRight = '8px';
    controlText.style.paddingTop = '3px';
    controlText.style.paddingBottom = '3px';

    controlText.innerHTML = name;
    controlUI.appendChild(controlText);

    currentText[maptype] = controlText;

    // Setup the click event listeners: simply set the map to Chicago
    google.maps.event.addDomListener(controlUI, 'click', function () {
        map.setMapTypeId(maptype);
        setCustomBold(maptype);
    });

    state.maplist.push(maptype);
}

// de-select all custom maps and optional set a map to bold

function setCustomBold(maptype, log) {
    if (!currentText) return;

    for (var key in currentText) {
        currentText[key].style.fontWeight = "normal";
        currentText[key].style.color = "#000000";
        currentText[key].style.background = "#FFFFFF";
    }

    // optional: set map to bold
    if (currentText[maptype]) {
        currentText[maptype].style.fontWeight = "bold";
        currentText[maptype].style.color = "#FFFFFF";
        currentText[maptype].style.background = "#4682B4";
    }

    maptype_usage(maptype);
}

function maptype_usage(maptype) {
    // get information about map type and log maptype
    if (bbbike.maptype_usage) {
        var url = "/cgi/maptype.cgi?city=" + city + "&maptype=" + maptype;

        if (state.maptype == maptype) return;
        state.maptype = maptype;

        downloadUrl(url, function (data, responseCode) {
            if (responseCode == 200) {
                //
            } else if (responseCode == -1) {
                //
            } else {
                // 
            }
        });
    }
}

// hide google only layers on 
// non-google custom maps
//

function hideGoogleLayers(maptype) {
    if (!maptype) {
        maptype = map.getMapTypeId()
    }

    var value = is_supported_maptype(maptype, bbbike.available_custom_maps) ? "hidden" : "visible";
    var timeout = 0; // value == "hidden" ? 2000 : 1000;
    setTimeout(function () {
        var div = document.getElementById("BicyclingLayer");
        if (div) div.style.visibility = value;
    }, timeout + (value == "hidden" ? 0 : 0));

    setTimeout(function () {
        var div = document.getElementById("TrafficLayer");
        if (div) div.style.visibility = value;
    }, timeout + (value == "hidden" ? 0 : 0));

/*
    setTimeout(function () {
        var div = document.getElementById("WeatherLayer");
        if (div) div.style.visibility = value;
    }, timeout - (value == "hidden" ? 900 : -900));
    */

    setCustomBold(maptype, 1);
}

var layerControl = {
/*
    TrafficLayer: false,
    BicyclingLayer: false,
    PanoramioLayer: false,
    Smoothness: true,
    VeloLayer: true,
    MaxSpeed: true,
    LandShading: false
*/
};

function LayerControl(controlDiv, map, opt) {
    var layer = opt.layer;
    var enabled = opt.active;
    var callback = opt.callback;
    var lang = opt.lang;
    var id = opt.id;

    // Set CSS styles for the DIV containing the control
    // Setting padding to 5 px will offset the control
    // from the edge of the map
    var controlUI = document.createElement('DIV');
    controlUI.setAttribute("id", layer);

    var controlText = document.createElement('DIV');

    controlDiv.style.paddingTop = '5px';
    controlDiv.style.paddingRight = '2px';

    // Set CSS for the control border
    controlUI.style.backgroundColor = 'white';
    controlUI.style.borderStyle = 'solid';
    controlUI.style.borderWidth = '2px';
    controlUI.style.cursor = 'pointer';
    controlUI.style.textAlign = 'center';

    var layerText = layer;
    layerControl[layer] = false; // true // enabled; 
    toogleColor(true);

    // grey (off) <-> green (on)

    function toogleColor(toogle, text) {
        controlUI.style.color = toogle ? '#888888' : '#228b22';
        controlText.innerHTML = (text ? text + " " : "") + translate_mapcontrol(layerText, lang);
    }

    if (layer == "FullScreen") {
        controlUI.title = 'Click to enable/disable ' + translate_mapcontrol(layerText, lang);
    } else if (layer == "SlideShow") {
        controlUI.title = 'Click to run ' + translate_mapcontrol(layerText, lang);
    } else if (layer == "Replay") {
        controlUI.title = 'Click to replay route';
    } else {
        controlUI.title = 'Click to add the layer ' + layerText;
    }

    controlDiv.appendChild(controlUI);

    // Set CSS for the control interior
    // controlText.style.fontFamily = 'Arial,sans-serif';
    controlText.style.fontSize = '12px';
    controlText.style.paddingLeft = '8px';
    controlText.style.paddingRight = '8px';
    controlText.style.paddingTop = '1px';
    controlText.style.paddingBottom = '1px';

    controlText.innerHTML = translate_mapcontrol(layerText, lang);
    controlUI.appendChild(controlText);
    if (enabled) controlText.fontWeight = "bold";

    // switch enabled <-> disabled
    google.maps.event.addDomListener(controlUI, 'click', function () {
        toogleColor(layerControl[layer]);
        layerControl[layer] = layerControl[layer] ? false : true;
        callback(map, layerControl[layer], toogleColor);

        if (layerControl[layer]) maptype_usage(layer);
    });

}

function custom_map(maptype, lang, opt) {
    var homeControlDiv = document.createElement('DIV');
    var homeControl = new HomeControl(homeControlDiv, map, maptype, lang, opt);

    var position = bbbike.mapPosition["default"];
    if (bbbike.mapPosition[maptype]) {
        position = bbbike.mapPosition[maptype];
    }

    homeControlDiv.index = 1;
    map.controls[google.maps.ControlPosition[position]].push(homeControlDiv);
}

function custom_layer(map, opt) {
    if (!opt.enabled) return;

    var layerControlDiv = document.createElement('DIV');
    var layerControl = LayerControl(layerControlDiv, map, opt);
    debug_layer(opt.id);

    layerControlDiv.index = 1;
    map.controls[google.maps.ControlPosition.RIGHT_TOP].push(layerControlDiv);
}


function displayCurrentPosition(area, lang) {
    if (!lang) lang = "en";

    if (!navigator.geolocation) {
        return;
    }

    navigator.geolocation.getCurrentPosition(function (position) {
        currentPosition = {
            "lat": position.coords.latitude,
            "lng": position.coords.longitude
        };

        var pos = new google.maps.LatLng(currentPosition.lat, currentPosition.lng);
        var marker = new google.maps.Marker({
            position: pos,
            icon: bbbike.icons["purple_dot"],
            map: map
        });

        var geocoder = new google.maps.Geocoder();
        geocoder.geocode({
            'latLng': pos
        }, function (results, status) {
            if (status != google.maps.GeocoderStatus.OK || !results[0]) {
                // alert("reverse geocoder failed to find an address for " + latlng.toUrlValue());
            } else {
                var result = results[0];

                // display info window at startup if inside the area
                if (area.length > 0) {
                    if (area[0][0] < currentPosition.lng && area[0][1] < currentPosition.lat && area[1][0] > currentPosition.lng && area[1][1] > currentPosition.lat) {

                        addInfoWindow(marker, result.formatted_address);

                        // hide window after N seconds
                        setTimeout(function () {
                            marker.setMap(null);
                            marker = new google.maps.Marker({
                                position: pos,
                                icon: bbbike.icons["purple_dot"],
                                map: map
                            });

                            google.maps.event.addListener(marker, "click", function (event) {
                                addInfoWindow(marker, result.formatted_address)
                            });

                        }, 5000);
                    }
                }

                // or later at click event
                google.maps.event.addListener(marker, "click", function (event) {
                    addInfoWindow(marker, result.formatted_address)
                });
            }
        });

        // google.maps.event.addListener(marker, "click", function(event) { addInfoWindow(marker) } );

        function addInfoWindow(marker, address) {
            infoWindow = new google.maps.InfoWindow({
                disableAutoPan: true,
                maxWidth: 400
            });
            var content = "<div id=\"infoWindowContent\">\n"
            content += "<p class='grey'>" + translate_mapcontrol("Your current postion", lang) + ": " + currentPosition.lat + "," + currentPosition.lng + "</p>\n";
            content += "<p>" + translate_mapcontrol("Approximate address", lang) + ": " + address + "</p>\n";
            // content += "<p>" + translate_mapcontrol("From here") + " " + translate_mapcontrol("To here") + "</p>\n";
            content += "</div>\n";
            infoWindow.setContent(content);
            infoWindow.open(map, marker);

        };
    });
}

// elevation.js
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

// Load the Visualization API and the piechart package.
try {
    google.load("visualization", "1", {
        packages: ["columnchart"]
    });
} catch (e) {}

// Set a callback to run when the Google Visualization API is loaded.
// google.setOnLoadCallback(elevation_initialize);

function elevation_initialize(slippymap, opt) {
    var myLatlng = new google.maps.LatLng(15, 0);
    var myOptions = {
        zoom: 1,
        center: myLatlng,
        // mapTypeId: google.maps.MapTypeId.TERRAIN
    }

    var maptype = slippymap.maptype;
    if (is_supported_map(maptype)) {
        // state.maptype = maptype;
        setCustomBold(maptype);
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

    google.visualization.events.addListener(chart, 'onmouseover', function (e) {
        if (mousemarker == null) {
            mousemarker = new google.maps.Marker({
                position: elevations[e.row].location,
                map: map,
                icon: bbbike.icons.purple_dot
            });
        } else {
            mousemarker.setPosition(elevations[e.row].location);
        }
    });

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

function loadRoute(opt) {
    reset();
    // map.setMapTypeId( google.maps.MapTypeId.ROADMAP );
    if (opt.maptype) {
        map.setMapTypeId(opt.maptype);
    }

    var bounds = new google.maps.LatLngBounds();
    for (var i = 0; i < marker_list.length; i++) {
        var latlng = new google.maps.LatLng(marker_list[i][0], marker_list[i][1]);
        addMarker(latlng, false);
        bounds.extend(latlng);
    }
    map.fitBounds(bounds);
    updateElevation();
    RouteMarker(opt);
}


function RouteMarker(opt) {

    // up to 3 markers: [ start, ziel, via ]
    var icons = [bbbike.icons.green, bbbike.icons.red, bbbike.icons.yellow];

    for (var i = 0; i < marker_list_points.length; i++) {
        var point = new google.maps.LatLng(marker_list_points[i][0], marker_list_points[i][1]);

        var marker = new google.maps.Marker({
            position: point,
            icon: icons[i],
            map: map
        });

        google.maps.event.addListener(marker, "click", function (marker) {
            return function (event) {
                addInfoWindow(marker)
            };
        }(marker));
    }

    function driving_time(driving_time) {
        var data = "";
        var time = driving_time.split('|');
        for (var i = 0; i < time.length; i++) {
            var t = time[i].split(':');
            data += t[0] + ":" + t[1] + "h (at " + t[2] + "km/h) ";
        }
        return data;
    }

    function addInfoWindow(marker) {
        if (infoWindow) {
            infoWindow.close();
        }

        infoWindow = new google.maps.InfoWindow({
            maxWidth: 400
        });

        var content = "<div id=\"infoWindowContent\">\n"
        content += "City: " + '<a target="_new" href="/' + opt.city + '/">' + opt.city + '</a>' + "<br/>\n";
        content += "<img height='12' src='" + icons[0] + "' /> " + "Start: " + opt.startname + "<br/>\n";
        if (opt.vianame && opt.vianame != "") {
            content += "<img height='12' src='" + icons[2] + "' /> " + "Via: " + opt.vianame + "<br/>\n";
        }
        content += "<img height='12' src='" + icons[1] + "' /> " + "Destination: " + opt.zielname + "<br/>\n";
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

function smallerMap(step, id, id2) {
    if (!id) id = "BBBikeGooglemap";
    if (!step) step = 2;

    var tag = document.getElementById(id);
    if (!tag) return;

    var width = tag.style.width || "75%";

    // match "75%" and increase it by step=1 
    var matches = width.match(/^([0-9\.\-]+)%$/);

    var unit = "%";
    var m = 0;
    if (matches) {
        m = parseFloat(matches[0]) - step;
    }
    if (m <= 0 || m > 105) m = 75;

    // make map smaller, and move it right
    tag.style.width = m + unit;
    tag.style.left = (100 - m) + unit;

    // debug("M: " + m + " " + tag.style.width + " " + tag.style.left );
}

//
// set start/via/ziel markers
// zoom level is not known yet, try it 0.5 seconds later
//

function init_markers(opt) {
    var timeout = setTimeout(function () {
        _init_markers(opt)
    }, 900);

    // reset markers after the map bound were changed
    google.maps.event.addListener(map, "bounds_changed", function () {
        clearTimeout(timeout);
        timeout = setTimeout(function () {
            _init_markers(opt)
        }, 1000);
    });
}

function _init_markers(opt) {
    var area = opt.area;
    var lang = opt.lang || "en";

    var zoom = map.getZoom();
    var ne = map.getBounds().getNorthEast();
    var sw = map.getBounds().getSouthWest();

    var lat, lng;
    if (area) {
        lat = area[1][0];
        lng = area[0][1];
    }

    // use current map size instead area
    else {
        lat = ne.lat();
        lng = sw.lng();
    }

    var dist = bbbike.search_markers_pos; // use 3.5 or 8
    var pos_lng = lng + (ne.lng() - lng) / dist; //  right
    var pos_lat = lat - (lat - sw.lat()) / dist; //  down
    padding = (ne.lng() - lng) / 16; // distance beteen markers on map, 1/x of the map
    var pos_start = new google.maps.LatLng(pos_lat, pos_lng);
    var pos_ziel = new google.maps.LatLng(pos_lat, pos_lng + padding);
    var pos_via = new google.maps.LatLng(pos_lat, pos_lng + 2.0 * padding);

    // shadow for markers, if moved
    var shadow = new google.maps.MarkerImage(bbbike.icons["shadow"], new google.maps.Size(49.0, 32.0), new google.maps.Point(0, 0), new google.maps.Point(16.0, 16.0));

    var marker_start = new google.maps.Marker({
        position: pos_start,
        clickable: true,
        draggable: true,
        title: translate_mapcontrol("Set start point", lang),
        icon: bbbike.icons["start"] // icon: "/images/start_ptr.png"
    });

    var marker_ziel = new google.maps.Marker({
        position: pos_ziel,
        clickable: true,
        draggable: true,
        title: translate_mapcontrol("Set destination point", lang),
        icon: bbbike.icons["ziel"] // icon: "/images/ziel_ptr.png"
    });

    var marker_via = new google.maps.Marker({
        position: pos_via,
        clickable: true,
        draggable: true,
        title: translate_mapcontrol("Set via point", lang),
        icon: bbbike.icons["via"] // icon: "/images/ziel_ptr.png"
    });


    // clean old markers
    debug("zoom level: " + map.getZoom() + " padding: " + padding);

    if (state.markers_drag.marker_start == null) {
        if (state.markers.marker_start) state.markers.marker_start.setMap(null);
        marker_start.setMap(map);
        state.markers.marker_start = marker_start;
    }
    if (state.markers_drag.marker_ziel == null) {
        if (state.markers.marker_ziel) state.markers.marker_ziel.setMap(null);
        marker_ziel.setMap(map);
        state.markers.marker_ziel = marker_ziel;
    }
    if (state.markers_drag.marker_via == null) {
        if (state.markers.marker_via) state.markers.marker_via.setMap(null);
        marker_via.setMap(map);
        state.markers.marker_via = marker_via;
    }



    // var event = 'position_changed'; // "drag", Firefox bug
    var event = 'drag'; // "drag", Firefox bug
    google.maps.event.addListener(marker_start, event, function () {
        state.markers_drag.marker_start = marker_start;
        find_street(marker_start, "suggest_start", shadow)
    });
    google.maps.event.addListener(marker_ziel, event, function () {
        state.markers_drag.marker_ziel = marker_ziel;
        find_street(marker_ziel, "suggest_ziel", shadow)
    });
    google.maps.event.addListener(marker_via, event, function () {
        state.markers_drag.marker_via = marker_via;
        find_street(marker_via, "suggest_via", shadow, function () {
            displayVia()
        });
    });
}

function displayVia() {
    var tag = document.getElementById("viatr");
    if (tag && tag.style.display == "none") toogleVia('viatr', 'via_message');
}

// round up to 1.1 meters

function granularity(val, gran) {
    var granularity = gran || bbbike.granularity;

    return parseInt(val * granularity) / granularity;
}

function debug(text, id) {
    // log to JavaScript console
    if (typeof console === "undefined" || typeof console.log === "undefined") { /* ARGH!!! old IE */
    } else {
        console.log("BBBike extract: " + text);
    }

    if (!id) id = "debug";

    var tag = jQuery("#" + id);
    if (!tag) return;

    // log to HTML page
    tag.html("debug: " + text);
}

function find_street(marker, input_id, shadow, callback) {
    var latLng = marker.getPosition();

    var input = document.getElementById(input_id);
    if (input) {
        if (input_id == "XXXsuggest_via") {
            toogleVia('viatr', 'via_message', null, true);
        }

        var value = granularity(latLng.lng()) + ',' + granularity(latLng.lat());
        input.setAttribute("value", value);

        // set shadow to indicate an active marker
        if (shadow) marker.setShadow(shadow);

        display_current_crossing(marker, input_id, {
            "lng": granularity(latLng.lng()),
            "lat": granularity(latLng.lat()),
            "callback": callback
        });

        var type = input_id.substr(8);
        var color = document.getElementById("icon_" + type);
        if (bbbike.dark_icon_colors && color) {
            color.setAttribute("bgcolor", type == "start" ? "green" : type == "ziel" ? "red" : "yellow");
        }

        // debug(value);
    } else {
        debug("Unknonw: " + input_id);
    }
}

/*************************************************
 * crossings
 *
 */

function inside_area(obj) { // { lng: lng, lat: lat }
    var area = state.marker_list;
    var bottomLeft = area[0];
    var topRight = area[1];

    var result;
    if (obj.lng >= bottomLeft[1] && obj.lng <= topRight[1] && obj.lat >= bottomLeft[0] && obj.lat <= topRight[0]) {
        result = 1;
    } else {
        result = 0;
    }

    debug("lng: " + obj.lng + " lat: " + obj.lat + " area: " + bottomLeft[1] + "," + bottomLeft[0] + " " + topRight[0] + "," + topRight[1] + " result: " + result);
    return result;
}

// call the API only after 100ms

function display_current_crossing(marker, id, obj) {
    if (state.timeout_crossing) {
        clearTimeout(state.timeout_crossing);
    }

    state.timeout_crossing = setTimeout(function () {
        _display_current_crossing(marker, id, obj)
    }, 100);
}

function _display_current_crossing(marker, id, obj) {
    var lngLat = obj.lng + "," + obj.lat
    var url = '/cgi/crossing.cgi?id=' + id + ';ns=dbac;city=' + city + ';q=' + lngLat;

    if (!inside_area(obj)) {
        debug("outside area");
        var query = translate_mapcontrol("Error: outside area");
        return updateCrossing(marker, id, '{query:"[' + query + ']", suggestions:[]}');
    }
    downloadUrl(url, function (data, responseCode) {
        if (responseCode == 200) {
            if (obj.callback) obj.callback();
            updateCrossing(marker, id, data);

        } else if (responseCode == -1) {
            alert("Data request timed out. Please try later.");
        } else {
            alert("Request resulted in error. Check XML file is retrievable.");
        }
    });
}

function set_input_field(id, value) {
    var input = document.getElementById(id);

    if (input) {
        input.value = value;
    } else {
        debug("unknown input field: " + id);
        return;
    }

    debug("crossing: " + id + " " + value);
}

// data: { query:"7.44007,46.93205", suggestions:["7.44042,46.93287	Bondelistr./"] }

function updateCrossing(marker, id, data) {

    if (!data || data == "") {
        return set_input_field(id, "");
    }

    var js = eval("(" + data + ")");

    if (!js || !js.suggestions) {
        return set_input_field(id, "");
    }

    var value = js.suggestions[0];
    var v, street_latlng;

    if (value) {
        v = value.split("\t");
        street_latlng = v[1] + " [" + v[0] + ",0]";
    } else {
        street_latlng = js.query;
    }

    newInfoWindow(marker, {
        "id": id,
        "crossing": v ? v[1] : street_latlng
    });

    return set_input_field(id, street_latlng);
}

function newInfoWindow(marker, opt) {

    var infoWindow = new google.maps.InfoWindow({
        maxWidth: 450
    });

    var content = "<div id=\"infoWindowContent\">\n"
    content += "<p>"
    content += translate_mapcontrol(opt.id == "suggest_start" ? "Start" : opt.id == "suggest_ziel" ? "Destination" : "Via") + " ";
    content += translate_mapcontrol("crossing") + ": <br/>" + opt.crossing;
    content += "</p>"
    content += "</div>\n";

    infoWindow.setContent(content);
    infoWindow.open(map, marker);

    google.maps.event.addListener(marker, "click", function (event) {
        infoWindow.open(map, marker);
        setTimeout(function () {
            infoWindow.close()
        }, 3000);
    });

    // close info window after 3 seconds
    setTimeout(function () {
        infoWindow.close()
    }, 2000);
};

// strip trailing country name

function format_address(address) {
    var street = address.split(",");
    street.pop();
    return street.join(",");
}

function googleCodeAddress(address, callback, logger) {
    function log_geocoder(logger, status) {
        // log geocode requests status by '/cgi/log.cgi';
        if (logger && logger.url) {
            var logger_url = encodeURI(logger.url + "?type=gmaps-geocoder&city=" + logger.city + "&query=" + address + "&status=" + status);
            $.get(logger_url);
        }
    }

    // search for an address only in this specific area
    // var box = [[43.60000,-79.66000],[43.85000,-79.07000]];
    var box = state.marker_list;

    var bounds = new google.maps.LatLngBounds;
    bounds.extend(new google.maps.LatLng(box[0][0], box[0][1]), new google.maps.LatLng(box[1][0], box[1][1]));

    if (!state.geocoder) {
        state.geocoder = new google.maps.Geocoder();
    }


    state.geocoder.geocode({
        'address': address,
        'bounds': bounds
    }, function (results, status) {
        if (status == google.maps.GeocoderStatus.OK) {
            var autocomplete = '{ query:"' + address + '", suggestions:[';

            var streets = [];
            for (var i = 0; i < results.length; i++) {
                if (inside_area({
                    lat: results[i].geometry.location.lat(),
                    lng: results[i].geometry.location.lng()
                })) {
                    streets.push('"' + format_address(results[i].formatted_address) + ' [' + granularity(results[i].geometry.location.lng()) + ',' + granularity(results[i].geometry.location.lat()) + ',1]"');
                }
            }

            autocomplete += streets.join(",");
            autocomplete += '] }';

            callback(autocomplete);
            log_geocoder(logger, "0");
        } else {
            log_geocoder(logger, status);
            // alert("Geocode was not successful for the following reason: " + status);
        }
    });
}

function toogleDiv(id, value) {
    var tag = document.getElementById(id);
    if (!tag) return;

    tag.style.display = tag.style.display == "none" ? "block" : "none";
    setMapHeight();
}

/* set map height, depending on footer height */

function setMapHeight() {
    var height = jQuery("body").height() - jQuery('#bottom').height() - 15;
    if (height < 200) height = 200;
    var width = jQuery("body").width() - jQuery('#routing').width() - 20;

    jQuery('#BBBikeGooglemap').height(height);
    jQuery('#BBBikeGooglemap').width(width);

    debug("height: " + height + ", width: " + width);
};

// EOF
