/**
 * Namespace: Util.OSM
 */
OpenLayers.Util.OSM = {};

/**
 * Constant: MISSING_TILE_URL
 * {String} URL of image to display for missing tiles
 */
OpenLayers.Util.OSM.MISSING_TILE_URL = "http://www.openstreetmap.org/openlayers/img/404.png";

/**
 * Property: originalOnImageLoadError
 * {Function} Original onImageLoadError function.
 */
OpenLayers.Util.OSM.originalOnImageLoadError = OpenLayers.Util.onImageLoadError;

/**
 * Function: onImageLoadError
 */
OpenLayers.Util.onImageLoadError = function() {
    if (this.src.match(/^http:\/\/[abc]\.[a-z]+\.openstreetmap\.org\//)) {
        this.src = OpenLayers.Util.OSM.MISSING_TILE_URL;
    } else if (this.src.match(/^http:\/\/[def]\.tah\.openstreetmap\.org\//)) {
        // do nothing - this layer is transparent
    } else {
        OpenLayers.Util.OSM.originalOnImageLoadError;
    }
};

/**
 * Class: OpenLayers.Layer.OSM.Mapnik
 *
 * Inherits from:
 *  - <OpenLayers.Layer.OSM>
 */
OpenLayers.Layer.OSM.Mapnik = OpenLayers.Class(OpenLayers.Layer.OSM, {
    /**
     * Constructor: OpenLayers.Layer.OSM.Mapnik
     *
     * Parameters:
     * name - {String}
     * options - {Object} Hashtable of extra options to tag onto the layer
     */
    initialize: function(name, options) {
        var url = [
            "http://a.tile.openstreetmap.org/${z}/${x}/${y}.png",
            "http://b.tile.openstreetmap.org/${z}/${x}/${y}.png",
            "http://c.tile.openstreetmap.org/${z}/${x}/${y}.png"
        ];
        options = OpenLayers.Util.extend({
            numZoomLevels: 20,
            buffer: 0,
            transitionEffect: "resize"
        }, options);
        var newArguments = [name, url, options];
        OpenLayers.Layer.OSM.prototype.initialize.apply(this, newArguments);
    },

    CLASS_NAME: "OpenLayers.Layer.OSM.Mapnik"
});

/**
 * Class: OpenLayers.Layer.OSM.Osmarender
 *
 * Inherits from:
 *  - <OpenLayers.Layer.OSM>
 */
OpenLayers.Layer.OSM.Osmarender = OpenLayers.Class(OpenLayers.Layer.OSM, {
    /**
     * Constructor: OpenLayers.Layer.OSM.Osmarender
     *
     * Parameters:
     * name - {String}
     * options - {Object} Hashtable of extra options to tag onto the layer
     */
    initialize: function(name, options) {
        var url = [
            "http://a.tah.openstreetmap.org/Tiles/tile/${z}/${x}/${y}.png",
            "http://b.tah.openstreetmap.org/Tiles/tile/${z}/${x}/${y}.png",
            "http://c.tah.openstreetmap.org/Tiles/tile/${z}/${x}/${y}.png"
        ];
        options = OpenLayers.Util.extend({
            numZoomLevels: 18,
            buffer: 0,
            transitionEffect: "resize"
        }, options);
        var newArguments = [name, url, options];
        OpenLayers.Layer.OSM.prototype.initialize.apply(this, newArguments);
    },

    CLASS_NAME: "OpenLayers.Layer.OSM.Osmarender"
});

/**
 * Class: OpenLayers.Layer.OSM.CycleMap
 *
 * Inherits from:
 *  - <OpenLayers.Layer.OSM>
 */
OpenLayers.Layer.OSM.CycleMap = OpenLayers.Class(OpenLayers.Layer.OSM, {
    /**
     * Constructor: OpenLayers.Layer.OSM.CycleMap
     *
     * Parameters:
     * name - {String}
     * options - {Object} Hashtable of extra options to tag onto the layer
     */
    initialize: function(name, options) {
        var url = [
            "http://a.tile.opencyclemap.org/cycle/${z}/${x}/${y}.png",
            "http://b.tile.opencyclemap.org/cycle/${z}/${x}/${y}.png",
            "http://c.tile.opencyclemap.org/cycle/${z}/${x}/${y}.png"
        ];
        options = OpenLayers.Util.extend({
            numZoomLevels: 19,
            buffer: 0,
            transitionEffect: "resize"
        }, options);
        var newArguments = [name, url, options];
        OpenLayers.Layer.OSM.prototype.initialize.apply(this, newArguments);
    },

    CLASS_NAME: "OpenLayers.Layer.OSM.CycleMap"
});


/**
 * Class: OpenLayers.Layer.Yahoo
 *
 * Inherits from:
 *  - <OpenLayers.Layer.EventPane>
 *  - <OpenLayers.Layer.FixedZoomLevels>
 */
OpenLayers.Layer.Yahoo = OpenLayers.Class(
  OpenLayers.Layer.EventPane, OpenLayers.Layer.FixedZoomLevels, {

    /**
     * Constant: MIN_ZOOM_LEVEL
     * {Integer} 0
     */
    MIN_ZOOM_LEVEL: 0,

    /**
     * Constant: MAX_ZOOM_LEVEL
     * {Integer} 17
     */
    MAX_ZOOM_LEVEL: 17,

    /**
     * Constant: RESOLUTIONS
     * {Array(Float)} Hardcode these resolutions so that they are more closely
     *                tied with the standard wms projection
     */
    RESOLUTIONS: [
        1.40625,
        0.703125,
        0.3515625,
        0.17578125,
        0.087890625,
        0.0439453125,
        0.02197265625,
        0.010986328125,
        0.0054931640625,
        0.00274658203125,
        0.001373291015625,
        0.0006866455078125,
        0.00034332275390625,
        0.000171661376953125,
        0.0000858306884765625,
        0.00004291534423828125,
        0.00002145767211914062,
        0.00001072883605957031
    ],

    /**
     * APIProperty: type
     * {YahooMapType}
     */
    type: null,

    /**
     * APIProperty: wrapDateLine
     * {Boolean} Allow user to pan forever east/west.  Default is true.
     *     Setting this to false only restricts panning if
     *     <sphericalMercator> is true.
     */
    wrapDateLine: true,

    /**
     * APIProperty: sphericalMercator
     * {Boolean} Should the map act as a mercator-projected map? This will
     * cause all interactions with the map to be in the actual map projection,
     * which allows support for vector drawing, overlaying other maps, etc.
     */
    sphericalMercator: false,

    /**
     * Constructor: OpenLayers.Layer.Yahoo
     *
     * Parameters:
     * name - {String}
     * options - {Object}
     */
    initialize: function(name, options) {
        OpenLayers.Layer.EventPane.prototype.initialize.apply(this, arguments);
        OpenLayers.Layer.FixedZoomLevels.prototype.initialize.apply(this,
                                                                    arguments);
        if(this.sphericalMercator) {
            OpenLayers.Util.extend(this, OpenLayers.Layer.SphericalMercator);
            this.initMercatorParameters();
        }
    },

    /**
     * Method: loadMapObject
     */
    loadMapObject:function() {
        try { //do not crash!
            var size = this.getMapObjectSizeFromOLSize(this.map.getSize());
            this.mapObject = new YMap(this.div, this.type, size);
            this.mapObject.disableKeyControls();
            this.mapObject.disableDragMap();

            //can we do smooth panning? (moveByXY is not an API function)
            if ( !this.mapObject.moveByXY ||
                 (typeof this.mapObject.moveByXY != "function" ) ) {

                this.dragPanMapObject = null;
            }
        } catch(e) {}
    },

    /**
     * Method: onMapResize
     *
     */
    onMapResize: function() {
        try {
            var size = this.getMapObjectSizeFromOLSize(this.map.getSize());
            this.mapObject.resizeTo(size);
        } catch(e) {}
    },


    /**
     * APIMethod: setMap
     * Overridden from EventPane because we need to remove this yahoo event
     *     pane which prohibits our drag and drop, and we can only do this
     *     once the map has been loaded and centered.
     *
     * Parameters:
     * map - {<OpenLayers.Map>}
     */
    setMap: function(map) {
        OpenLayers.Layer.EventPane.prototype.setMap.apply(this, arguments);

        this.map.events.register("moveend", this, this.fixYahooEventPane);
    },

    /**
     * Method: fixYahooEventPane
     * The map has been centered, so the mysterious yahoo eventpane has been
     *     added. we remove it so that it doesnt mess with *our* event pane.
     */
    fixYahooEventPane: function() {
        var yahooEventPane = OpenLayers.Util.getElement("ygddfdiv");
        if (yahooEventPane != null) {
            if (yahooEventPane.parentNode != null) {
                yahooEventPane.parentNode.removeChild(yahooEventPane);
            }
            this.map.events.unregister("moveend", this,
                                       this.fixYahooEventPane);
        }
    },

    /**
     * APIMethod: getWarningHTML
     *
     * Returns:
     * {String} String with information on why layer is broken, how to get
     *          it working.
     */
    getWarningHTML:function() {
        return OpenLayers.i18n(
            "getLayerWarning", {'layerType':'Yahoo', 'layerLib':'Yahoo'}
        );
    },

  /********************************************************/
  /*                                                      */
  /*             Translation Functions                    */
  /*                                                      */
  /*    The following functions translate GMaps and OL    */
  /*     formats for Pixel, LonLat, Bounds, and Zoom      */
  /*                                                      */
  /********************************************************/


  //
  // TRANSLATION: MapObject Zoom <-> OpenLayers Zoom
  //

    /**
     * APIMethod: getOLZoomFromMapObjectZoom
     *
     * Parameters:
     * gZoom - {Integer}
     *
     * Returns:
     * {Integer} An OpenLayers Zoom level, translated from the passed in gZoom
     *           Returns null if null value is passed in.
     */
    getOLZoomFromMapObjectZoom: function(moZoom) {
        var zoom = null;
        if (moZoom != null) {
            zoom = OpenLayers.Layer.FixedZoomLevels.prototype.getOLZoomFromMapObjectZoom.apply(this, [moZoom]);
            zoom = 18 - zoom;
        }
        return zoom;
    },

    /**
     * APIMethod: getMapObjectZoomFromOLZoom
     *
     * Parameters:
     * olZoom - {Integer}
     *
     * Returns:
     * {Integer} A MapObject level, translated from the passed in olZoom
     *           Returns null if null value is passed in
     */
    getMapObjectZoomFromOLZoom: function(olZoom) {
        var zoom = null;
        if (olZoom != null) {
            zoom = OpenLayers.Layer.FixedZoomLevels.prototype.getMapObjectZoomFromOLZoom.apply(this, [olZoom]);
            zoom = 18 - zoom;
        }
        return zoom;
    },

    /************************************
     *                                  *
     *   MapObject Interface Controls   *
     *                                  *
     ************************************/


  // Get&Set Center, Zoom

    /**
     * APIMethod: setMapObjectCenter
     * Set the mapObject to the specified center and zoom
     *
     * Parameters:
     * center - {Object} MapObject LonLat format
     * zoom - {int} MapObject zoom format
     */
    setMapObjectCenter: function(center, zoom) {
        this.mapObject.drawZoomAndCenter(center, zoom);
    },

    /**
     * APIMethod: getMapObjectCenter
     *
     * Returns:
     * {Object} The mapObject's current center in Map Object format
     */
    getMapObjectCenter: function() {
        return this.mapObject.getCenterLatLon();
    },

    /**
     * APIMethod: dragPanMapObject
     *
     * Parameters:
     * dX - {Integer}
     * dY - {Integer}
     */
    dragPanMapObject: function(dX, dY) {
        this.mapObject.moveByXY({
            'x': -dX,
            'y': dY
        });
    },

    /**
     * APIMethod: getMapObjectZoom
     *
     * Returns:
     * {Integer} The mapObject's current zoom, in Map Object format
     */
    getMapObjectZoom: function() {
        return this.mapObject.getZoomLevel();
    },


  // LonLat - Pixel Translation

    /**
     * APIMethod: getMapObjectLonLatFromMapObjectPixel
     *
     * Parameters:
     * moPixel - {Object} MapObject Pixel format
     *
     * Returns:
     * {Object} MapObject LonLat translated from MapObject Pixel
     */
    getMapObjectLonLatFromMapObjectPixel: function(moPixel) {
        return this.mapObject.convertXYLatLon(moPixel);
    },

    /**
     * APIMethod: getMapObjectPixelFromMapObjectLonLat
     *
     * Parameters:
     * moLonLat - {Object} MapObject LonLat format
     *
     * Returns:
     * {Object} MapObject Pixel transtlated from MapObject LonLat
     */
    getMapObjectPixelFromMapObjectLonLat: function(moLonLat) {
        return this.mapObject.convertLatLonXY(moLonLat);
    },


    /************************************
     *                                  *
     *       MapObject Primitives       *
     *                                  *
     ************************************/


  // LonLat

    /**
     * APIMethod: getLongitudeFromMapObjectLonLat
     *
     * Parameters:
     * moLonLat - {Object} MapObject LonLat format
     *
     * Returns:
     * {Float} Longitude of the given MapObject LonLat
     */
    getLongitudeFromMapObjectLonLat: function(moLonLat) {
        return this.sphericalMercator ?
            this.forwardMercator(moLonLat.Lon, moLonLat.Lat).lon :
            moLonLat.Lon;
    },

    /**
     * APIMethod: getLatitudeFromMapObjectLonLat
     *
     * Parameters:
     * moLonLat - {Object} MapObject LonLat format
     *
     * Returns:
     * {Float} Latitude of the given MapObject LonLat
     */
    getLatitudeFromMapObjectLonLat: function(moLonLat) {
        return this.sphericalMercator ?
            this.forwardMercator(moLonLat.Lon, moLonLat.Lat).lat :
            moLonLat.Lat;
    },

    /**
     * APIMethod: getMapObjectLonLatFromLonLat
     *
     * Parameters:
     * lon - {Float}
     * lat - {Float}
     *
     * Returns:
     * {Object} MapObject LonLat built from lon and lat params
     */
    getMapObjectLonLatFromLonLat: function(lon, lat) {
        var yLatLong;
        if(this.sphericalMercator) {
            var lonlat = this.inverseMercator(lon, lat);
            yLatLong = new YGeoPoint(lonlat.lat, lonlat.lon);
        } else {
            yLatLong = new YGeoPoint(lat, lon);
        }
        return yLatLong;
    },

  // Pixel

    /**
     * APIMethod: getXFromMapObjectPixel
     *
     * Parameters:
     * moPixel - {Object} MapObject Pixel format
     *
     * Returns:
     * {Integer} X value of the MapObject Pixel
     */
    getXFromMapObjectPixel: function(moPixel) {
        return moPixel.x;
    },

    /**
     * APIMethod: getYFromMapObjectPixel
     *
     * Parameters:
     * moPixel - {Object} MapObject Pixel format
     *
     * Returns:
     * {Integer} Y value of the MapObject Pixel
     */
    getYFromMapObjectPixel: function(moPixel) {
        return moPixel.y;
    },

    /**
     * APIMethod: getMapObjectPixelFromXY
     *
     * Parameters:
     * x - {Integer}
     * y - {Integer}
     *
     * Returns:
     * {Object} MapObject Pixel from x and y parameters
     */
    getMapObjectPixelFromXY: function(x, y) {
        return new YCoordPoint(x, y);
    },

  // Size

    /**
     * APIMethod: getMapObjectSizeFromOLSize
     *
     * Parameters:
     * olSize - {<OpenLayers.Size>}
     *
     * Returns:
     * {Object} MapObject Size from olSize parameter
     */
    getMapObjectSizeFromOLSize: function(olSize) {
        return new YSize(olSize.w, olSize.h);
    },

    CLASS_NAME: "OpenLayers.Layer.Yahoo"
});


OpenLayers.Layer.Nokia = OpenLayers.Class(OpenLayers.Layer.XYZ, {
    // for reference: all supported layers
    layers: ["normal.day", "terrain.day", "satellite.day", "hybrid.day", "normal.day.transit", "newest/normal.day"],

    /**
     * APIProperty: name
     * {String} The layer name. Defaults to "OpenStreetMap" if the first
     * argument to the constructor is null or undefined.
     */
    name: "Nokia",

    /**
     * Property: key
     * {String} API key for Nokia maps, get your own key
     *     at http://developer.here.net/
     */
    app_id: null,
    token: null,

    /**
     * Property: attributionTemplate
     * {String}
     */
    attribution : '<span class="olNokiaAttribution">' +
         '<a target="_blank" href="http://maps.nokia.com/">Nokia.com</a>' +
         '</span>',


    /**
     * APIProperty: type
     * {String} The layer identifier.
     *     used.  Default is "normal.day".
     *
     */
    type: "normal.day",

    /** APIProperty: tileOptions
     *  {Object} optional configuration options for <OpenLayers.Tile> instances
     *  created by this Layer. Default is
     *
     *  (code)
     *  {crossOriginKeyword: 'anonymous'}
     *  (end)
     */
    tileOptions: {
        crossOriginKeyword: null
    },

    /**
     * Property: sphericalMercator
     * {Boolean}
     */
    sphericalMercator: true,

    /**
     * Constructor: OpenLayers.Layer.Nokia
     *
     * Parameters:
     * name - {String} The layer name.
     * url - {String} The tileset URL scheme.
     * options - {Object} Configuration options for the layer. Any inherited
     *     layer option can be set in this object (e.g.
     *     <OpenLayers.Layer.Grid.buffer>).
     */
    initialize: function(name, options) {
        OpenLayers.Layer.XYZ.prototype.initialize.apply(this, arguments);

        var type = (options.type || this.type);
        if (!checkLayerType(this.layers, type)) {
            throw "Unsupported Nokia map type: " + type;
        }

        name = name || this.name;
        var url = this.nokiaTileSeverUrl(type, {
            app_id: options.app_id,
            tile_id: options.tile_id,
            token: options.token
        });

        options = OpenLayers.Util.extend({
            numZoomLevels: 19
        }, options);

        var newArgs = [name, url, options];
        OpenLayers.Layer.XYZ.prototype.initialize.apply(this, newArgs);

        this.tileOptions = OpenLayers.Util.extend({
            crossOriginKeyword: 'anonymous'
        }, this.options && this.options.tileOptions);
    },

    // [http://4.maps.nlp.nokia.com/maptile/2.1/maptile/a2e328a0c5/normal.day/${z}/${x}/${y}/256/png8?app_id=abx&token=def&lg=ENG"]
    nokiaTileSeverUrl: function (type, opt) {
        var app_id = opt.app_id;
        var token = opt.token;
        var tile_id = opt.tile_id;
        var servers = opt.servers;

        if (!tile_id) // may change every 3 months (sic!)
            tile_id = "f8c7b21875";
        
        var urls = {
            "normal.day": "base.maps.api.here.com/maptile/2.1/maptile/" + tile_id,
            "terrain.day": "aerial.maps.api.here.com/maptile/2.1/maptile/" + tile_id,
            "satellite.day": "aerial.maps.api.here.com/maptile/2.1/maptile/" + tile_id,
            "hybrid.day": "aerial.maps.api.here.com/maptile/2.1/maptile/" + tile_id,
            "normal.day.transit": "base.maps.api.here.com/maptile/2.1/maptile/" + tile_id,
            "newest/normal.day": "traffic.maps.api.here.com/maptile/2.1/" + "traffictile"
        };
        
        var url_prefix = urls[type];

        // traffic layer use a different API
        if (!servers || servers.length == 0) {
            servers = ["1", "2", "3", "4"];
        }

        var url_list = [];
        for (var i = 0; i < servers.length; i++) {
            url_list.push("http://" + (servers[i] ? servers[i] + "." : "") + url_prefix + "/" + type + "/${z}/${x}/${y}/256/png8?app_id=" + app_id + "&token=" + token + "&lg=ENG");
        }

        return url_list;
    },

    /**
     * APIMethod: clone
     *
     * Parameters:
     * obj - {Object}
     *
     * Returns:
     * {<OpenLayers.Layer.Nokia>} An exact clone of this <OpenLayers.Layer.Nokia>
     */
    clone: function(obj) {
        if (obj == null) {
            obj = new OpenLayers.Layer.Nokia(this.options);
        }
        //get all additions from superclasses
        obj = OpenLayers.Layer.OSM.prototype.clone.apply(this, [obj]);
        // copy/set any non-init, non-simple values here
        return obj;
    },

    CLASS_NAME: "OpenLayers.Layer.Nokia"
});

function checkLayerType(layers, type) {
   for (var i = 0; i < layers.length; i++) {
        if (layers[i] == type)
            return true;
   }
   return false;
}
