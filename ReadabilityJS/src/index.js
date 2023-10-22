
var { Readability } = require('@mozilla/readability');
require("fastestsmallesttextencoderdecoder");
var { JSDOM } = require('jsdom');

var doc = new JSDOM("<html></html>", {});

global.window = doc.window;
global.setTimeout = global.window.setTimeout;

global.parseArticle = (url, html) => {
    var doc = new JSDOM(html, { url: url });

    let reader = new Readability(doc.window.document);
    let article = reader.parse()
    return article
}