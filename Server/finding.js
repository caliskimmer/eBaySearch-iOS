const express = require('express');
const http = require('http');
const findingRouter = express.Router();
const request = require('request-promise-native');
require('dotenv').config();

let categories = {
    'Art':                        550,
    'Baby':                       2984,
    'Books':                      267,
    'ClothingShoesAccessories':   11450,
    'ComputersTabletsNetworking': 58058,
    'HealthBeauty':               26395,
    'Music':                      11233,
    'VideoGamesConsoles':         1249
}

let constructUrl = function(req) {
    let params = [
        'OPERATION-NAME=findItemsAdvanced',
        'SERVICE-VERSION=1.0.0',
        `SECURITY-APPNAME=${process.env.SECURITY_APP_NAME}`,
        'RESPONSE-DATA-FORMAT=JSON',
        'REST-PAYLOAD',
        'paginationInput.entriesPerPage=50',
        'outputSelector(0)=SellerInfo',
        'outputSelector(1)=StoreInfo',
    ];

    // Construct params from request query
    params.push(`keywords=${req.query.keyword}`);

    if (req.query.category && categories[req.query.category]) {
        params.push(`categoryId=${categories[req.query.category]}`);
    }

    params.push(`buyerPostalCode=${req.query.postal}`);

    let itemFilterIndex = 0;
    let itemValueIndex = 0;

    params.push(`itemFilter(${itemFilterIndex}).name=HideDuplicateItems`);
    params.push(`itemFilter(${itemFilterIndex}).value=true`);
    itemFilterIndex++;

    if (req.query.conditionNew || req.query.conditionUsed || req.query.conditionUnspecified) {
        params.push(`itemFilter(${itemFilterIndex}).name=Condition`);

        if (req.query.conditionNew) {
            params.push(`itemFilter(${itemFilterIndex}).value(${itemValueIndex})=New`);
            itemValueIndex++;
        }
        if (req.query.conditionUsed) {
            params.push(`itemFilter(${itemFilterIndex}).value(${itemValueIndex})=Used`);
            itemValueIndex++;
        }
        if (req.query.conditionUnspecified) {
            params.push(`itemFilter(${itemFilterIndex}).value(${itemValueIndex})=Unspecified`);
        }
        itemFilterIndex++;
    }

    itemValueIndex = 0;
    if (req.query.freeShipping) {
        params.push(`itemFilter(${itemFilterIndex}).name=FreeShippingOnly`);
        params.push(`itemFilter(${itemFilterIndex}).value(${itemValueIndex})=true`);
        itemFilterIndex++;
        itemValueIndex++;
    }
    if (req.query.localShipping) {
        params.push(`itemFilter(${itemFilterIndex}).name=LocalShippingOnly`);
        params.push(`itemFilter(${itemFilterIndex}).value(${itemValueIndex})=true`);
        itemFilterIndex++;
    }

    params.push(`itemFilter(${itemFilterIndex}).name=MaxDistance`);
    if (req.query.distance) {
        params.push(`itemFilter(${itemFilterIndex}).value=${req.query.distance}`);
    } else {
        params.push(`itemFilter(${itemFilterIndex}).value=10`);
    }

    const baseUrl = 'http://svcs.ebay.com/services/search/FindingService/v1?';
    let query = '';
    for (const param of params) {
        query += `${param}&`;
    }
    query = query.slice(0,-1);

    return baseUrl + query;
};

let parseResult = function(items) {
    let response = {results: []};
    
    if (!items) {
        return response;    
    }

    for (const [index, item] of items.entries()) {
        let result = {};
        result['id'] = item['itemId'][0];
        result['index'] = index+1;
        result['image'] = item['galleryURL'] ? item['galleryURL'][0] : null;
        result['title'] = item['title'] ? item['title'][0] : null;
        result['url'] = item['viewItemURL'][0] || null;
        if (item['sellingStatus'] && item['sellingStatus'][0]['currentPrice']) {
            let cost = parseFloat(item['sellingStatus'][0]['currentPrice'][0]['__value__']);
            result['price'] = `\$${cost.toFixed(2)}`;
        } else {
            result['price'] = null;
        }
        if (item['shippingInfo']) {
            result['shipping'] = {};

            if (item['shippingInfo'][0]['shippingServiceCost']) {
                let shippingCost = parseFloat(item['shippingInfo'][0]['shippingServiceCost'][0]['__value__']);
                result['shipping']['type'] = (shippingCost === 0) ? 'Free Shipping' : `\$${shippingCost.toFixed(2)}`;
                result['shipping']['cost'] = `\$${shippingCost.toFixed(2)}`;
            } else {
                result['shipping']['type'] = null;
                result['shipping']['cost'] = null;
            }
            if (item['shippingInfo'][0]['shipToLocations']) {
                result['shipping']['locations'] = item['shippingInfo'][0]['shipToLocations'];
            }
            if (item['shippingInfo'][0]['handlingTime']) {
                result['shipping']['handlingTime'] = item['shippingInfo'][0]['handlingTime'][0];
            }
            if (item['shippingInfo'][0]['expeditedShipping']) {
                result['shipping']['expedited'] = item['shippingInfo'][0]['expeditedShipping'][0];
            }
            if (item['shippingInfo'][0]['oneDayShippingAvailable']) {
                result['shipping']['oneDayShipping'] = item['shippingInfo'][0]['oneDayShippingAvailable'][0];
            }
        }
        if (item['returnsAccepted']) {
            result['returnsAccepted'] = item['returnsAccepted'][0];
        }
        if (item['condition'] && item['condition'][0]['conditionId']) {
            result['condition'] = item['condition'][0]['conditionId'][0];
        }

        result['zip'] = item['postalCode'] ? item['postalCode'][0] : null;
        if (item['sellerInfo'] && item['sellerInfo'][0]['sellerUserName']) {
            result['seller'] = item['sellerInfo'][0]['sellerUserName'][0];
        } else {
            result['seller'] = null;
        }

        response['results'].push(result);
    }
    return response;
};

findingRouter.get('/', (req, res, next) => {
    let url = constructUrl(req);
    let options = {
        uri: url,
        json: true
    }
    request(options).then((result) => {
        let json = result['findItemsAdvancedResponse'][0]['searchResult'][0]['item'];
        res.json(parseResult(json));
        next();
    }).catch((err) => {
        console.log(err.error || err);

        let response = {
            results: [],
            error: true
        }
        res.json(response);
        next();
    });
});

module.exports = findingRouter;
