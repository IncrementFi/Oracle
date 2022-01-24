const config = require('./config');
const express = require('express');

const app = express();
const port = config.stateRestPort;

const feeder = require("./feeder");

require('log-timestamp');

app.use(express.json());

var G_OriginStates = {}
var G_PriceStates = {}
var G_LastOnChainPrices = {}

app.all('*', function(req, res, next) {
    res.header("Access-Control-Allow-Origin", "*");
    res.header("Access-Control-Allow-Headers", "X-Requested-With");
    res.header("Access-Control-Allow-Methods","GET");
    res.header("X-Powered-By",' 3.2.1')
    res.header("Content-Type", "application/json;charset=utf-8");
    next();
});

app.get('/states', async (req, res) => {
    var curPrices = {}
    for (priceName in G_LastOnChainPrices) {
        curPrices[priceName] = {}
        curPrices[priceName].price = G_LastOnChainPrices[priceName].price
        var localtime = new Date()
        var deltTime = localtime.getTime()/1000 - G_LastOnChainPrices[priceName].time
        curPrices[priceName].time = G_LastOnChainPrices[priceName].time
        curPrices[priceName].since = parseInt(deltTime/60)+"m "+parseInt(deltTime)%60+"s"
    }

    var code = {
        "OriginState": G_OriginStates,
        "PriceState": G_PriceStates,
        "UpdatePrice": curPrices
    }
    
    res.setHeader('Content-Type', 'application/json');
    res.end(JSON.stringify(code, null, 3));
});

app.listen(port, () => {
    console.log(`Get list at http://127.0.0.1:${port}/states`);
});


module.exports = {
    G_OriginStates,
    G_PriceStates,
    G_LastOnChainPrices
}