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

    var layerMapnik = new OpenLayers.Layer.OSM.Mapnik("OSM Mapnik");
    map.addLayer(layerMapnik);

    var layerCycleMap = new OpenLayers.Layer.OSM.CycleMap("OSM CycleMap");
    map.addLayer(layerCycleMap);

    map.addLayer(new OpenLayers.Layer.OSM("OSM Toner", ["http://a.tile.stamen.com/toner/${z}/${x}/${y}.png", "http://b.tile.stamen.com/toner/${z}/${x}/${y}.png"], {
        numZoomLevels: 18
    }));


    var switcherControl = new OpenLayers.Control.LayerSwitcher();
    map.addControl(switcherControl);

    switcherControl.maximizeControl();

    map.addControl(new OpenLayers.Control.LayerSwitcher());
    map.addControl(new OpenLayers.Control.Permalink());

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
    // This is the end of the layer
    // Begin of overlay
    map.addLayer(new OpenLayers.Layer.TMS("BBBike Fahrbahnqualit&auml;t", "/osm/bbbike-smoothness/", {
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

    map.addLayer(new OpenLayers.Layer.TMS("BBBike handicap", "/osm/bbbike-handicap/", {
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

    map.addLayer(new OpenLayers.Layer.TMS("BBBike cycle routes", "/osm/bbbike-cycle-routes/", {
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

    map.addLayer(new OpenLayers.Layer.TMS("BBBike cycleway", "/osm/bbbike-cycleway/", {
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

    map.addLayer(new OpenLayers.Layer.TMS("BBBike green", "/osm/bbbike-green/", {
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

    map.addLayer(new OpenLayers.Layer.TMS("BBBike unknown", "/osm/bbbike-unknown/", {
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

    map.addLayer(new OpenLayers.Layer.TMS("BBBike unlit", "/osm/bbbike-unlit/", {
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



    if (!map.getCenter()) {
        var lonLat = new OpenLayers.LonLat(lon, lat).transform(new OpenLayers.Projection("EPSG:4326"), map.getProjectionObject());
        map.setCenter(lonLat, zoom);
    }
}
