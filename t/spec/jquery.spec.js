/* Copyright (c) 2013 Wolfram Schneider, http://bbbike.org
 *
 * jQuery test
 *
 */

describe("jQuery suite simple", function () {
    var $ = require('jquery');

    it("jQuery append test", function () {
        $("body").append("<h1>test passes h1</h1>");
        expect($("body").html()).toMatch(/<h1>/);
        $("<p>this is a paragraph</p>").appendTo("h1");
        expect($("body").html()).toMatch(/this is a paragraph/);
    });

    it("$ append test", function () {
        $("<h2>test passes h2</h2>").appendTo("body");
        expect($("body").html()).toMatch(/<h2>/);

        $("<p>this is a second paragraph</p>").appendTo("h1");
        expect($("body").html()).toMatch(/this is a paragraph/);
    });

    it("more jquery tests", function () {
        // other tests
        expect($("h2").html()).toMatch(/test passes h2/);
        expect($("h1").html()).toMatch(/test passes h1/);
        expect($("h1").html()).not.toMatch(/^$/);
        expect($("h1").html()).not.toMatch(/foobar/);
    });
});
