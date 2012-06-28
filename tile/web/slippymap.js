// Start position for the map (hardcoded here for simplicity)
var lat = 52.51703;
var lon = 13.38885;
var zoom = 15;

var map; //complex object of type OpenLayers.Map
//Initialise the 'map' object

function init() {

    map = new OpenLayers.Map("map", {
        controls: [
        new OpenLayers.Control.Navigation(), new OpenLayers.Control.PanZoomBar(), new OpenLayers.Control.Permalink(), new OpenLayers.Control.ScaleLine({
            geodesic: true
        }), new OpenLayers.Control.Permalink('permalink'), new OpenLayers.Control.MousePosition(), new OpenLayers.Control.Attribution()],
        maxExtent: new OpenLayers.Bounds(-20037508.34, -20037508.34, 20037508.34, 20037508.34),
        maxResolution: 156543.0339,
        numZoomLevels: 19,
        units: 'm',
        projection: new OpenLayers.Projection("EPSG:900913"),
        displayProjection: new OpenLayers.Projection("EPSG:4326")
    });

    // This is the layer that uses the locally stored tiles
    map.addLayer(new OpenLayers.Layer.OSM("BBBike.org Mapnik (de)", "mapnik-german/${z}/${x}/${y}.png", {
        numZoomLevels: 19,
        attribution: '<a href="http://bbbike.org/">BBBike.org</a>'
    }));

    map.addLayer(new OpenLayers.Layer.OSM("BBBike.org Mapnik", "mapnik/${z}/${x}/${y}.png", {
        numZoomLevels: 19,
        attribution: '<a href="http://bbbike.org/">BBBike.org</a>'
    }));

    map.addLayer(new OpenLayers.Layer.OSM.Mapnik("OSM Mapnik"));

    map.addLayer(new OpenLayers.Layer.OSM("OSM Mapnik (de)", "http://a.tile.openstreetmap.de/tiles/osmde/${z}/${x}/${y}.png", {
        numZoomLevels: 18
    }));

    map.addLayer(new OpenLayers.Layer.OSM("OSM Mapnik b/w", "http://a.www.toolserver.org/tiles/bw-mapnik/${z}/${x}/${y}.png", {
        numZoomLevels: 18
    }));
    map.addLayer(new OpenLayers.Layer.OSM("OSM Toner", ["http://a.tile.stamen.com/toner/${z}/${x}/${y}.png","http://b.tile.stamen.com/toner/${z}/${x}/${y}.png"], {
        numZoomLevels: 18
    }));
    map.addLayer(new OpenLayers.Layer.OSM("OSM Watercolor", ["http://a.tile.stamen.com/watercolor/${z}/${x}/${y}.png","http://b.tile.stamen.com/watercolor/${z}/${x}/${y}.png"], {
        numZoomLevels: 18
    }));

    map.addLayer(new OpenLayers.Layer.OSM("OSM Transport", ["http://a.tile2.opencyclemap.org/transport/${z}/${x}/${y}.png", "http://b.tile2.opencyclemap.org/transport/${z}/${x}/${y}.png"], {
        numZoomLevels: 19
    }));

    map.addLayer(new OpenLayers.Layer.OSM("OSM Landscape", ["http://a.tile3.opencyclemap.org/landscape/${z}/${x}/${y}.png", "http://b.tile3.opencyclemap.org/landscape/${z}/${x}/${y}.png"], {
        numZoomLevels: 19
    }));

    map.addLayer(new OpenLayers.Layer.OSM("OSM OEPNV", ["http://a.tile.xn--pnvkarte-m4a.de/tilegen/${z}/${x}/${y}.png", "http://b.tile.xn--pnvkarte-m4a.de/tilegen/${z}/${x}/${y}.png"], {
        numZoomLevels: 18
    }));

    map.addLayer(new OpenLayers.Layer.OSM("OSM Hike&Bike", ["http://a.www.toolserver.org/tiles/hikebike/${z}/${x}/${y}.png", "http://b.www.toolserver.org/tiles/hikebike/${z}/${x}/${y}.png"], {
        numZoomLevels: 18
    }));

    map.addLayer(new OpenLayers.Layer.OSM.CycleMap("OSM CycleMap"));

    map.addLayer(new OpenLayers.Layer.OSM("OSM Wanderreitkarte", ["http://base.wanderreitkarte.de/base/${z}/${x}/${y}.png", "http://base2.wanderreitkarte.de/base/${z}/${x}/${y}.png"], {
        numZoomLevels: 18
    }));

    map.addLayer(new OpenLayers.Layer.OSM("OSM MapBox", ["http://a.tiles.mapbox.com/v3/mapbox.mapbox-streets/${z}/${x}/${y}.png", "http://b.tiles.mapbox.com/v3/mapbox.mapbox-streets/${z}/${x}/${y}.png"], {
        numZoomLevels: 17
    }));

    map.addLayer(new OpenLayers.Layer.OSM("Esri", "http://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/${z}/${y}/${x}.png", {
        numZoomLevels: 18
    }));

    map.addLayer(new OpenLayers.Layer.OSM("Esri Topographic", "http://services.arcgisonline.com/ArcGIS/rest/services/World_Topo_Map/MapServer/tile/${z}/${y}/${x}.png", {
        numZoomLevels: 18
    }));

    map.addLayer(new OpenLayers.Layer.OSM("Mapquest EU (OSM)", ["http://otile1.mqcdn.com/tiles/1.0.0/osm/${z}/${x}/${y}.png", "http://otile2.mqcdn.com/tiles/1.0.0/osm/${z}/${x}/${y}.png"], {
        numZoomLevels: 19
    }));

    map.addLayer(new OpenLayers.Layer.OSM("Mapquest US (OSM)", ["http://mtile01.mqcdn.com/tiles/1.0.0/vy/map/${z}/${x}/${y}.png", "http://mtile02.mqcdn.com/tiles/1.0.0/vy/map/${z}/${x}/${y}.png"], {
        numZoomLevels: 19
    }));

    map.addLayer(new OpenLayers.Layer.OSM("Mapquest Satellite", ["http://mtile01.mqcdn.com/tiles/1.0.0/vy/sat/${z}/${x}/${y}.png", "http://mtile02.mqcdn.com/tiles/1.0.0/vy/sat/${z}/${x}/${y}.png"], {
        numZoomLevels: 19
    }));

    map.addLayer(new OpenLayers.Layer.OSM("Skobbler (OSM)", ["http://tiles1.skobbler.net/osm_tiles2/${z}/${x}/${y}.png", "http://tiles2.skobbler.net/osm_tiles2/${z}/${x}/${y}.png"], {
        numZoomLevels: 19
    }));

    map.addLayer(new OpenLayers.Layer.OSM("Apple iPhoto (OSM)", ["http://gsp2.apple.com/tile?api=1&style=slideshow&layers=default&lang=de_DE&z=${z}&x=${x}&y=${y}&v=9"], {
        numZoomLevels: 15
    }));

    map.addLayer(new OpenLayers.Layer.Google("Google Physical", {
        type: google.maps.MapTypeId.TERRAIN,
        'sphericalMercator': true,
        attribution: ', <a href="http://maps.google.com/">Google</a>',
        numZoomLevels: 16
    }));

    map.addLayer(new OpenLayers.Layer.Google("Google Roadmap", {
        type: google.maps.MapTypeId.ROADMAP,
        'sphericalMercator': true,
        attribution: ', <a href="http://maps.google.com/">Google</a>',
        numZoomLevels: 19
    }));

    map.addLayer(new OpenLayers.Layer.Google("Google Satellite", {
        type: google.maps.MapTypeId.SATELLITE,
        'sphericalMercator': true,
        attribution: ', <a href="http://maps.google.com/">Google</a>',
        numZoomLevels: 19
    }));

    map.addLayer(new OpenLayers.Layer.Google("Google Hybrid", {
        type: google.maps.MapTypeId.HYBRID,
        'sphericalMercator': true,
        attribution: ', <a href="http://maps.google.com/">Google</a>',
        numZoomLevels: 19
    }));

    map.addLayer(new OpenLayers.Layer.Yahoo("Yahoo Street", {
        'sphericalMercator': true,
        attribution: '<a href="http://yahoo.com/">Yahoo Local Maps</a>',
        numZoomLevels: 18
    }));

    map.addLayer(new OpenLayers.Layer.Yahoo("Yahoo Aerial", {
        'type': YAHOO_MAP_SAT,
        'sphericalMercator': true,
        attribution: '<a href="http://yahoo.com/">Yahoo Local Maps</a>',
        numZoomLevels: 18
    }));

    map.addLayer(new OpenLayers.Layer.Yahoo("Yahoo Hybrid", {
        'type': YAHOO_MAP_HYB,
        'sphericalMercator': true,
        attribution: '<a href="http://yahoo.com/">Yahoo Local Maps</a>',
        numZoomLevels: 18
    }));

    function bing() {
        var apiKey = "AqTGBsziZHIJYYxgivLBf0hVdrAk9mWO5cQcb8Yux8sW5M8c8opEC2lZqKR1ZZXf";

        // var map = new OpenLayers.Map( 'map');
        var road = new OpenLayers.Layer.Bing({
            key: apiKey,
            type: "Road",
            // custom metadata parameter to request the new map style - only useful
            // before May 1st, 2011
            metadataParams: {
                mapVersion: "v1"
            }
        });
        var aerial = new OpenLayers.Layer.Bing({
            key: apiKey,
            type: "Aerial"
        });
        var hybrid = new OpenLayers.Layer.Bing({
            key: apiKey,
            type: "AerialWithLabels",
            name: "Bing Aerial With Labels"
        });

        map.addLayers([road, aerial, hybrid]);
    };
    bing();
    // This is the end of the layer
    // Begin of overlay
    map.addLayer(new OpenLayers.Layer.TMS("BBBike Fahrbahnqualit&auml;t", "bbbike-smoothness/", {
        type: 'png',
        getURL: osm_getTileURL,
        displayOutsideMaxExtent: true,
        attribution: '<a href="http://bbbike.de/">BBBike</a>',
        opacity: 1,
        isBaseLayer: false,
        visibility: false,
        numZoomLevels: 19,
        noOpaq: true
    }));

    map.addLayer(new OpenLayers.Layer.TMS("ADFC Radwegenetz", "", {
        type: 'png',
        getURL: get_mm_bikeTracks,
        displayOutsideMaxExtent: true,
        attribution: '<a href="http://www.adfc.de/">ADFC</a>',
        opacity: 1,
        isBaseLayer: false,
        visibility: false,
        numZoomLevels: 17,
        noOpaq: true
    }));

    map.addLayer(newLayer = new OpenLayers.Layer.XYZ("Velo-Layer", "http://toolserver.org/tiles/bicycle/${z}/${x}/${y}.png", {
        attribution: '<a href="http://osm.t-i.ch/bicycle/map/">Velo-Layer</a>',
        opacity: 1,
        isBaseLayer: false,
        visibility: false,
        numZoomLevels: 19,
        noOpaq: true
    }));

    map.addLayer(newLayer = new OpenLayers.Layer.XYZ("Max Speed", "http://wince.dentro.info/koord/osm/tiles/${z}/${x}/${y}.png", {
        attribution: '<a href="http://wince.dentro.info/koord/osm/KosmosMap.htm">MaxSpeedMap</a>',
        opacity: 1,
        isBaseLayer: false,
        visibility: false,
        numZoomLevels: 15,
        noOpaq: true
    }));

    map.addLayer(new OpenLayers.Layer.TMS("Hillshading SRTM3 V2", "http://toolserver.org/~cmarqu/hill/", {
        type: 'png',
        getURL: osm_getTileURL,
        displayOutsideMaxExtent: true,
        attribution: '<a href="http://toolserver.org/~cmarqu/hill/">Hillshading SRTM3 V2</a>',
        opacity: 1,
        isBaseLayer: false,
        visibility: false,
        numZoomLevels: 19,
        noOpaq: true
    }));

    map.addLayer(new OpenLayers.Layer.TMS("Land Shading", "http://tiles2.openpistemap.org/landshaded/", {
        type: 'png',
        getURL: osm_getTileURL,
        displayOutsideMaxExtent: true,
        attribution: '<a href="http://tiles2.openpistemap.org/landshaded/">Land Shading</a>',
        opacity: 1,
        isBaseLayer: false,
        visibility: false,
        numZoomLevels: 19,
        noOpaq: true
    }));

    map.addLayer(new OpenLayers.Layer.OSM("OSM Public Transport Lines", "http://www.openptmap.org/tiles/${z}/${x}/${y}.png", { maxZoomLevel: 17, numZoomLevels: 18, alpha: true, isBaseLayer: false, visibility: false}) );

    var switcherControl = new OpenLayers.Control.LayerSwitcher();
    map.addControl(switcherControl);
    map.addControl(new OpenLayers.Control.LayerSwitcher());
    map.addControl(new OpenLayers.Control.Permalink());
    // switcherControl.maximizeControl();
    // ADFC

    function get_mm_bikeTracks(bounds) {
        llbounds = new OpenLayers.Bounds();
        llbounds.extend(OpenLayers.Layer.SphericalMercator.inverseMercator(bounds.left, bounds.bottom));
        llbounds.extend(OpenLayers.Layer.SphericalMercator.inverseMercator(bounds.right, bounds.top));
        url = "http://mm-lbserver.dnsalias.com/mm-mapserver_v2/wms/wms.php?REQUEST=GetMap&SERVICE=WMS&VERSION=1.1.1&LAYERS=MM_BIKETRACKS&STYLES=&FORMAT=image/png&BGCOLOR=0xFFFFFF&TRANSPARENT=TRUE&SRS=EPSG:4326&BBOX="
        url = url + llbounds.toBBOX() + "&WIDTH=256&HEIGHT=256"
        return url
    }

    // bbbike?

    function osm_getTileURL(bounds) {
        var res = this.map.getResolution();
        var x = Math.round((bounds.left - this.maxExtent.left) / (res * this.tileSize.w));
        var y = Math.round((this.maxExtent.top - bounds.top) / (res * this.tileSize.h));
        var z = this.map.getZoom();
        var limit = Math.pow(2, z);

        if (y < 0 || y >= limit) {
            return OpenLayers.Util.getImagesLocation() + "404.png";
        } else {
            x = ((x % limit) + limit) % limit;
            return this.url + z + "/" + x + "/" + y + "." + this.type;
        }
    }

    if (!map.getCenter()) {
        var lonLat = new OpenLayers.LonLat(lon, lat).transform(new OpenLayers.Projection("EPSG:4326"), map.getProjectionObject());
        map.setCenter(lonLat, zoom);
    }
}

// 1;
