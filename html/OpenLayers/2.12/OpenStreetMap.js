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
