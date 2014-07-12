/* Copyright (c) 2006-2014 by OpenLayers Contributors (see authors.txt for 
 * full list of contributors). Published under the 2-clause BSD license.
 * See license.txt in the OpenLayers distribution or repository for the
 * full text of the license. */

/* Written by Wolfram Schneider, 2012-2014
 * Map Compare BBBike: http://mc.bbbike.org/mc
 *
 * based on XYZ.js and Bing.js example code
 */

/**
 * @requires OpenLayers/Layer/XYZ.js
 */

/** 
 * Class: OpenLayers.Layer.Here
 * Here layer using direct tile access as provided by Here Maps REST Services.
 * See http://developer.here.net/ for more
 * information. Note: Terms of Service compliant use requires the map to be
 * configured with an <OpenLayers.Control.Attribution> control and the
 * attribution placed on or near the map.
 * 
 * Inherits from:
 *  - <OpenLayers.Layer.XYZ>
 */

/**
 * Example: map = new OpenLayers.Layer.Here("Here Map", { type: "normal.day", app_id: "abcdefgh"})
 */

OpenLayers.Layer.Here = OpenLayers.Class(OpenLayers.Layer.XYZ, {
    // for reference: all supported layers
    layers: ["normal.day", "terrain.day", "satellite.day", "hybrid.day", "normal.day.transit", "newest/normal.day"],

    /**
     * APIProperty: name
     * {String} The layer name. Defaults to "OpenStreetMap" if the first
     * argument to the constructor is null or undefined.
     */
    name: "Here",

    /**
     * Property: key
     * {String} API key for Here maps, get your own key
     *     at http://developer.here.net/
     */
    app_id: null,
    token: null,

    /**
     * Property: attributionTemplate
     * {String}
     */
    attribution : '<span class="olHereAttribution">' +
         '<a target="_blank" href="http://maps.here.com/">Here.com</a>' +
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
     * Constructor: OpenLayers.Layer.Here
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
        if (!this.checkLayerType(this.layers, type)) {
            throw "Unsupported Here map type: " + type;
        }

        name = name || this.name;
        var url = this.hereTileSeverUrl(type, {
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

    // [http://4.maps.nlp.here.com/maptile/2.1/maptile/a2e328a0c5/normal.day/${z}/${x}/${y}/256/png8?app_id=abx&token=def&lg=ENG"]
    hereTileSeverUrl: function (type, opt) {
        var app_id = opt.app_id;
        var token = opt.token;
        var tile_id = opt.tile_id;
        var servers = opt.servers;

        if (!tile_id) // may change every 3 months (sic!)
            tile_id = "newest";
        
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
    
    checkLayerType: function(layers, type) {
        for (var i = 0; i < layers.length; i++) {
            if (layers[i] == type)
                return true;
        }
        return false;
    },

    /**
     * APIMethod: clone
     *
     * Parameters:
     * obj - {Object}
     *
     * Returns:
     * {<OpenLayers.Layer.Here>} An exact clone of this <OpenLayers.Layer.Here>
     */
    clone: function(obj) {
        if (obj == null) {
            obj = new OpenLayers.Layer.Here(this.options);
        }
        //get all additions from superclasses
        obj = OpenLayers.Layer.OSM.prototype.clone.apply(this, [obj]);
        // copy/set any non-init, non-simple values here
        return obj;
    },

    CLASS_NAME: "OpenLayers.Layer.Here"
});
