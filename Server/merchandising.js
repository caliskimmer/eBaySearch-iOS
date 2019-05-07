const express = require('express');
const http = require('http');
const merchRouter = express.Router();
const request = require('request-promise-native');
require('dotenv').config();

let constructUrl = function(req) {
    let params = [
        'OPERATION-NAME=getSimilarItems',
        'SERVICE-NAME=MerchandisingService',
        'SERVICE-VERSION=1.1.0',
        `CONSUMER-ID=${process.env.SECURITY_APP_NAME}`,
        'RESPONSE-DATA-FORMAT=JSON',
        'REST-PAYLOAD',
        `itemId=${req.query.itemID}`,
        'maxResults=20'
    ];

    const baseUrl = 'http://svcs.ebay.com/MerchandisingService?';
    let query = '';
    for (const param of params) {
        query += `${param}&`;
    }
    query = query.slice(0,-1);
    return baseUrl + query;
}

let parseResult = function(items) {
    let results = {'items': []};
    for (let item of items) {
        let result = {};
        result['title'] = item['title'];
        result['url'] = item['viewItemURL'];
        if (item['imageURL']) {
            result['imageURL'] = item['imageURL'];
        }
        if (item['buyItNowPrice']) {
            result['price'] = `\$${parseFloat(item['buyItNowPrice']['__value__']).toFixed(2)}`;
        }
        if (item['shippingCost']) {
            result['shipping'] = `\$${parseFloat(item['shippingCost']['__value__']).toFixed(2)}`;
        }
        if (item['timeLeft']) {
            result['daysLeft'] = item['timeLeft'].substring(1, item['timeLeft'].indexOf('D'));
        }
        results['items'].push(result);
    }

    return results;
};

merchRouter.get('/', (req, res, next) => {
    let url = constructUrl(req);
    let options = {
        uri: url
    }
    request(options).then((result) => {
        result = JSON.parse(result);
        let json = result['getSimilarItemsResponse']['itemRecommendations']['item'];
        res.json(parseResult(json));
        next();
    }).catch((err) => {
        console.log(err);
        
        let results = {
            'items': [],
            error: true
        };
        res.json(results);
        next();
    });
});

module.exports = merchRouter;
