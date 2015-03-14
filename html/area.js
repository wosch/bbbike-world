/* for city.cgi 
 *
 */

// var bbbike_db = [ .... ];

function plot_bbbike_areas(bbbike_db, offline) {

    var data = "";
    for (var i = 0; i < bbbike_db.length; i++) {
        var coords = bbbike_db[i][1];
        var c = bbbike_db[i][0];

        download_plot_polygon({
            "color": "orange",
            "sw_lng": coords[0],
            "sw_lat": coords[1],
            "ne_lng": coords[2],
            "ne_lat": coords[3]
        });

        // footer links
        data += '<a href="';
        if (offline) {
            data += '../' + c + '/';
        } else {
            data += '?city=' + c;
        }

        data += '">' + c + '</a>\n';
    }

    $("#more_cities_inner").html(data);
}

function set_map_height() {
    var padding = 0; // XXX: browser problems?
    var height = $("body").height() - $('#bottom').height() - padding;
    if (height < 200) height = 200;

    $('#BBBikeGooglemap, #map_wrapper').height(height);

    debug("set_map_height: body hight: " + $("body").height() + " height: " + height);
};

function jump_to_city(bbbike_db, city) {
    var obj;
    for (var i = 0; i < bbbike_db.length; i++) {
        obj = bbbike_db[i];
        if (obj[0] == city) {
            center_city(obj[1], obj[2], obj[3], obj[4]);
            return;
        }
    }
    debug("did not found city in db: " + city);
}

function toggle_more_cities(id) {
    var tag_more_cities = $("#" + id);

    tag_more_cities.toggle();
    set_map_height();
}

function init_map_resize() {
    var resize = null;

    // set map height depending on the free space on the browser window
    set_map_height();

    // reset map size, 3x a second
    $(window).resize(function () {
        if (resize) clearTimeout(resize);
        resize = setTimeout(function () {
            debug("resize event");
            set_map_height();
        }, 100);
    });
}
