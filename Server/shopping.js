const express = require('express');
const http = require('http');
const shoppingRouter = express.Router();
const request = require('request-promise-native');
require('dotenv').config();

let constructUrl = function(req) {
    let params = [
        'callname=GetSingleItem',
        'responseencoding=JSON',
        `appid=${process.env.SECURITY_APP_NAME}`,
        'siteid=0',
        'version=967',
        `ItemID=${req.query.itemId}`,
        'IncludeSelector=Description,Details,ItemSpecifics,ShippingCosts'
    ];

    const baseUrl = 'http://open.api.ebay.com/shopping?';
    let query = '';
    for (const param of params) {
        query += `${param}&`;
    }
    query = query.slice(0,-1);

    return baseUrl + query;
}

let parseResult = function(item) {
    let result = {
        'Images': item['PictureURL'] || [],
        'Title': item['Title'],
        'Subtitle': item['Subtitle'] || null,
        'Price': (item['CurrentPrice']) ? `\$${parseFloat(item['CurrentPrice']['Value']).toFixed(2)}` : null,
        'Location': item['Location'],
        'URL': item['ViewItemURLForNaturalSearch']
    };

    result['Other'] = [];
    if (item['ItemSpecifics']) {
        for (let key of item['ItemSpecifics']['NameValueList']) {
            let spec = {};
            spec['Name'] = key['Name'];

            spec['Value'] = ''
            for (value of key['Value']) {
                spec['Value'] += `${value},`;
            }
            spec['Value'] = spec['Value'].slice(0, -1);

            result['Other'].push(spec);
        }
    }

    if (item['Seller']) {
        result['Seller'] = {};
        result['Seller']['Seller'] = item['Seller']['UserID'];
        result['Seller']['Score'] = item['Seller']['FeedbackScore'];
        result['Seller']['Popularity'] = item['Seller']['PositiveFeedbackPercent'];
        result['Seller']['Rating'] = item['Seller']['FeedbackRatingStar'];
        if (item['Seller']['TopRatedSeller']) {
            result['Seller']['IsTopRated'] = item['Seller']['TopRatedSeller'];
        }
    }

    if (item['Storefront']) {
        result['Store'] = {};
        result['Store']['Name'] = item['Storefront']['StoreName'];
        result['Store']['URL'] = item['Storefront']['StoreURL'];
    }

    result['Shipping'] = {}
    if (item['GlobalShipping'] != null) {
        result['Shipping']['GlobalShipping'] = (item['GlobalShipping']) ? 'Yes' : 'No';
    }
    if (item['HandlingTime']) {
        const days = (item['HandlingTime'] === 1) ? 'day' : 'days';
        result['Shipping']['HandlingTime'] = `${item['HandlingTime']} ${days}`;
    }
    let shippingServiceCost = item['ShippingCostSummary']['ShippingServiceCost'];
    if (shippingServiceCost) {
        result['Shipping']['Cost'] = (shippingServiceCost['Value'] === 0) ? 'FREE' : `\$${shippingServiceCost['Value'].toFixed(2)}`;
    }

    if (!item['ReturnPolicy']) {
        return result;
    }
    if (item['ReturnPolicy']['ReturnsAccepted']) {
        result['ReturnPolicy'] = item['ReturnPolicy']['ReturnsAccepted'];
        result['ReturnPolicyType'] = result['ReturnPolicy'];
    }
    if (item['ReturnPolicy']['ReturnsWithin']) {
        result['ReturnPolicy'] = `${result['ReturnPolicy']} Within ${item['ReturnPolicy']['ReturnsWithin']}`;
        result['ReturnPolicyDays'] = item['ReturnPolicy']['ReturnsWithin'];
    }
    if (item['ReturnPolicy']['ShippingCostPaidBy']) {
        result['ReturnPolicyShippingCostPaidBy'] = item['ReturnPolicy']['ShippingCostPaidBy'];
    }
    if (item['ReturnPolicy']['Refund']) {
        result['ReturnPolicyRefund'] = item['ReturnPolicy']['Refund'];
    }

    return result;
}

shoppingRouter.get('/', (req, res, next) => {
    let url = constructUrl(req);
    let options = {
        uri: url,
        json: true
    }
    request(options).then((result) => {
        let json = result['Item'];
        res.json(parseResult(json));
        next();
    }).catch((err) => {
        console.log(err.error || err);

        let result = {
            'error': true
        };
        res.json(result);
        next();
    });
});

module.exports = shoppingRouter;
