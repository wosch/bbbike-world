/* Copyright (c) 2013 Wolfram Schneider, http://bbbike.org
 *
 * jQuery test with DOM/windows object
 *
 */

describe("jQuery suite", function () {
    var jsdom = require('jsdom').jsdom;
    var myWindow = jsdom().createWindow();

    var $ = require('jquery');
    var jq = require('jquery').create();
    var jQuery = require('jquery').create(myWindow);

    it("jQuery append test", function () {
        jQuery("<h1>test passes h1</h1>").appendTo("body");
        expect(jQuery("body").html()).toMatch(/<h1>/);
    });

    it("$ append test", function () {
        $("<h2>test passes h2</h2>").appendTo("body");
        expect($("body").html()).toMatch(/<h2>/);
    });

    it("jq append test", function () {
        jq("<h2>test passes h2</h2>").appendTo("body");
        expect(jq("body").html()).toMatch(/<h2>/);
    });

    it("window test", function () {
        expect(myWindow).toBeDefined();
    });
});
