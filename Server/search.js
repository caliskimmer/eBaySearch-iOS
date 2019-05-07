const express = require('express');
const http = require('http');
const searchRouter = express.Router();
const request = require('request-promise-native');

let constructUrl = function(req) {
    let params = [
        `q=${encodeURI(req.query.productTitle)}`,
        `cx=${process.env.SEARCH_ENGINE_ID}`,
        'imgSize=huge',
        'imgType=news',
        'num=8',
        'searchType=image',
        `key=${process.env.GOOGLE_API_KEY}`
    ];

    const baseUrl = 'https://www.googleapis.com/customsearch/v1?';
    let query = '';
    for (const param of params) {
        query += `${param}&`;
    }
    query = query.slice(0, -1);

    return baseUrl + query;
}

let parseResult = function(items) {
    let result = {'images': []};

    if (!items) {
        result['error'] = 'No Items Found'
        return result;
    }

    for (let item of items) {
        result.images.push(item['link']);
    }

    return result;
}

searchRouter.get('/', (req, res, next) => {
    let url = constructUrl(req);
    let options = {
        uri: url,
        json: true
    };
    request(options).then((result) => {
        let json = result['items'];
        res.send(parseResult(json));
        next();
    }).catch((err) => {
        console.log(err.error || err);

        let response = {
            'images': [],
            'error': true
        };
        res.send(response);
        next();
    });
});

//autocomplete
searchRouter.get('/postal', (req, res, next) => {
    let url = `http://api.geonames.org/postalCodeSearchJSON?postalcode_startsWith=${req.query.zip}&username=${process.env.GEONAMES_USER}&country=US&maxRows=5`;
    let options = {
        uri: url,
        json: true
    };
    request(options).then((result) => {
        let postalCodes = {results: []};
        
        if (!result['postalCodes']) {
            postalCodes['results']['error'] = 'postalCodes object does not exist';
            res.json(postalCodes);
            next();
        }

        let zips = [];
        for (const loc of result['postalCodes']) {
            zips.push(loc['postalCode']);
        }
        
        postalCodes['results'] = zips;
        res.json(postalCodes);
        next();
    }).catch((err) => {
        console.log(err.error || err);
        res.json(response);
        next();
    });
});

module.exports = searchRouter;
