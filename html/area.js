/* for city.cgi 
 *
 */

// var bbbike_db = [ .... ];

function plot_bbbike_areas(bbbike_db, offline) {

var data = "";
for(var i = 0; i < bbbike_db.length; i++) {
    var obj = bbbike_db[i];
    var c = obj[0];
    
    download_plot_polygon( {"color": "orange",
     "sw_lng":  obj[1], "sw_lat": obj[2], "ne_lng": obj[3], "ne_lat": obj[4]});
    
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
    var padding = 10; // XXX: browser problems?
    
    var height = $("body").height() - $('#bottom').height() - padding;
    if (height < 200) height = 200;

    $('#BBBikeGooglemap, #map_wrapper').height(height);

    debug("set_map_height: body hight: " + $("body").height() + " height: " + height);
};

function jump_to_city(bbbike_db, city) {
  var obj;
  for(var i = 0; i < bbbike_db.length; i++) {
	obj = bbbike_db[i];
	if (obj[0] == city) {
	    center_city(obj[1], obj[2], obj[3], obj[4]);
	    return;
	}
  }
  debug("did not found city in db: " + city);
}

    function resizeOtherCities(toogle) {
	var tag = document.getElementById("BBBikeGooglemap");
	var tag_more_cities = document.getElementById("more_cities");
    
	if (!tag) return;
	if (!tag_more_cities) return;
    
	if (!toogle) {
	    // tag.style.height = "75%";
	    // tag_more_cities.style.fontSize = "85%";
	    tag_more_cities.style.display = "block";
    
	} else {
	    tag_more_cities.style.display = "none";
	    // tag.style.height = "90%";
	}
    
	more_cities = toogle ? false : true;
	// google.maps.event.trigger(map, 'resize');
	set_map_height();
    }
    
