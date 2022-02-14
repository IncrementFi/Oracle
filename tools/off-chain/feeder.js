const config = require('./config.json');
const FlowOracleAPI = require('./flow/FlowOracleAPI');
const states = require('./states');
require('log-timestamp');


function collectAllPairsFromSameOrigin() {
    var originToAllPairs = {}

    for (let price in config.prices) {
        var method = config.prices[price].method;
        var params = config.prices[price].params;
        var origins = config.prices[price].origins;
        for (let i = 0; i < origins.length; ++i) {
            var originExchangeList = origins[i];
            for (let j = 0; j < originExchangeList.length; ++j) {
                var pairJson = originExchangeList[j];
                var origin = pairJson.origin;
                var pair = pairJson.pair;

                if (!originToAllPairs.hasOwnProperty(origin)) originToAllPairs[origin] = {}
                originToAllPairs[origin][pair] = 0.0
            }
        }
    }

    return originToAllPairs
}

async function pullAllPricesFromOrigins(originToAllPairs) {
    var originToAllPrices = {}
    for (let origin in originToAllPairs) {
        if (origin == ".") continue

        const originApi = require('./origins/'+origin+'.js');
        var pairs = originToAllPairs[origin]
        try {
            states.G_OriginStates[origin] = "good"
            //console.log("pull price from", origin, "at ", pairs)
            var pullRes = await originApi.PullPrice(pairs)

            originToAllPrices[origin] = pullRes
        } catch (err) {
            console.error(err)
            states.G_OriginStates[origin] = err
        }
    }

    return originToAllPrices
}

function mergePriceFromOrigins(priceName, allPricesToOrigins, finalPrices) {
    var method = config.prices[priceName].method;
    var params = config.prices[priceName].params;
    var origins = config.prices[priceName].origins;
    
    var curPriceToOrigin = {}
    states.G_PriceStates[priceName] = {}
    for (let i = 0; i < origins.length; ++i) {
        var originExchangeList = origins[i];

        var curOriginName = ""
        
        var accOriginPrice = 1.0
        var ifHasPrice = true
        for (let j = 0; j < originExchangeList.length; ++j) {
            var pairJson = originExchangeList[j];
            var origin = pairJson.origin;
            var pair = pairJson.pair;

            if (j == 0) curOriginName = origin
            var curOriginPrice
            if (origin == ".") {
                if (!(pair in finalPrices) ) {
                    ifHasPrice = false
                    break
                }
                curOriginPrice = finalPrices[pair]
            } else {

                if (!(origin in allPricesToOrigins)) {
                    ifHasPrice = false
                    break
                }
                if (!(pair in allPricesToOrigins[origin])) {
                    ifHasPrice = false
                    break
                }
                curOriginPrice = allPricesToOrigins[origin][pair].price
            }
            //
            accOriginPrice *= curOriginPrice
        }
        if (ifHasPrice) {
            curPriceToOrigin[curOriginName] = accOriginPrice
            states.G_PriceStates[priceName][curOriginName] = accOriginPrice
        } else {
            states.G_PriceStates[priceName][curOriginName] = "null"
        }
    }
    // weighted
    return integratePrices(method, params, curPriceToOrigin, priceName)
}

function calOraclePrice(allPricesToOrigins) {
    var finalPrices = {}
    // fist round cal the ./ price
    for (let priceName in config.prices) {
        var price = mergePriceFromOrigins(priceName, allPricesToOrigins, finalPrices)
        if (price > 0) {
            finalPrices[priceName] = price
        }
    }
    // second round cal the other prices
    for (let priceName in config.prices) {
        if ((priceName in finalPrices) && finalPrices[priceName] > 0) {
            continue
        }
        var price = mergePriceFromOrigins(priceName, allPricesToOrigins, finalPrices)

        if (price > 0) {
            finalPrices[priceName] = price
        }
    }

    return finalPrices
}

function integratePrices(method, params, prices, targetPriceName){
    var price = 0.0
    if (method == "weighted-average") {
        var totalWeight = 0.0
        var totalValue = 0.0
        let weights = params.weights
        let minOriginNumber = params.minOriginNumber

        if( Object.keys(prices).length < minOriginNumber) {
            return 0.0
        }
        for (let curOrigin in prices) {
            let curWeight = weights[curOrigin]
            let curPrice = prices[curOrigin]

            totalWeight += curWeight
            totalValue += curWeight * curPrice
        }

        var price = totalValue / totalWeight
    }

    return price
}

function timeout(ms) {
	return new Promise(resolve => setTimeout(resolve, ms));
}

async function publishPriceWithTimeout(priceName, curPrice) {
	await Promise.race([
        FlowOracleAPI.publishPrice(priceName, curPrice),
        
		timeout(40000).then(() => {
			throw new Error("tx time out")
		}),
	]).then().catch( (err)=>{ console.log(err); throw(err) } )
}
async function publishPriceOnChain(priceName, curPrice) {
    try {
        //await FlowOracleAPI.publishPrice(priceName, curPrice)
        await publishPriceWithTimeout(priceName, curPrice)
        console.log("tx update succ",priceName, curPrice)
        states.G_LastOnChainPrices[priceName] = {}
        states.G_LastOnChainPrices[priceName].price = curPrice
        
        let localtime = new Date();
        let utc = localtime.getTime()/1000

        states.G_LastOnChainPrices[priceName].time = utc
    } catch(err) {
        console.error('tx error', err, priceName, curPrice)
    }
}

async function pullAllPrices_Hearbeat(originToAllPairs) {
    console.log('pull prices')
    //
    var allPricesToOrigins = await pullAllPricesFromOrigins(originToAllPairs)
    //
    var finalPrice = calOraclePrice(allPricesToOrigins)
    
    for (priceName in finalPrice) {
        var curPrice = parseFloat(finalPrice[priceName]).toFixed(8)

        let localtime = new Date();
        let utc = localtime.getTime()/1000
        var curTime = utc

        var lastPrice = 0.0
        var lastTime = 0
        if (priceName in states.G_LastOnChainPrices) {
            lastPrice = states.G_LastOnChainPrices[priceName].price
            lastTime = states.G_LastOnChainPrices[priceName].time
        }
        // update
        var windowSize = config.prices[priceName].update.windowSize
        var deviation = config.prices[priceName].update.deviation
        if(curTime - lastTime > windowSize) {
            console.log('over time publish', priceName, lastPrice, 'to', curPrice)
            await publishPriceOnChain(priceName, curPrice)
        } else if(lastPrice == 0.0 && curPrice > 0.0) {
            console.log('first publish', priceName, lastPrice, 'to', curPrice)
            await publishPriceOnChain(priceName, curPrice)
        } else if(Math.abs((curPrice-lastPrice)/lastPrice) > deviation) {
            console.log('over price publish', priceName, lastPrice, 'to', curPrice)
            await publishPriceOnChain(priceName, curPrice)
        }
    }

    setTimeout(pullAllPrices_Hearbeat, config.heartbeat, originToAllPairs)
}

(async () => {
    var originToAllPairs = collectAllPairsFromSameOrigin()
    
    pullAllPrices_Hearbeat(originToAllPairs)
})()

