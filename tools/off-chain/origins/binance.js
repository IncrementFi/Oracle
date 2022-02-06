const http = require("./http");

// docs: https://binance-docs.github.io/apidocs/spot/en/#24hr-ticker-price-change-statistics
const binanceURL_all = "https://www.binance.com/api/v3/ticker/price"
const binanceURL_one = "https://www.binance.com/api/v3/ticker/price?symbol="

function pairFormat(pair) {
	return pair.replace('/', '')
}

async function requestOne(pair) {
	var url = binanceURL_one + pairFormat(pair);
	var respJson
	var resp = await http.request(url)
	try {
		respJson = await resp.json()
	} catch(err) {
		throw( Error("binance parse request error ["+url+"]") )
	}

	return respJson
}

async function requestAll(pairs) {
	var respJson = []
	if (Object.keys(pairs).length > 3 ) {
		var resp = await http.request(binanceURL_all)
		try {
			respJson = await resp.json()
		} catch {
			throw( Error("binance parse request all result json error.") )
		}
	} else {
		for (let pair in pairs) {
			respJson.push( await requestOne(pair) )
		}
	}
	var res = {}
	
	if (respJson.length > 0) {
		res = await parseResponse(respJson, pairs)
	} else {
		throw(Error("binance respJson error."));
	}
	return res
}

async function parseResponse(respJson, pairs) {
	var res = {}
	var respMap = {}
	for (let i = 0; i < respJson.length; ++i) {
		var symbol = respJson[i].symbol
		var price = respJson[i].price
		respMap[symbol] = price
	}

	for (let pair in pairs) {
		var pairWithoutSlash = pairFormat(pair)
		if (!(pairWithoutSlash in respMap)) {
			throw(Error("binance pair resp mismatch error: "+pair));
		}
		var price = respMap[pairWithoutSlash]
		res[pair] = {
			price: parseFloat(price),
			timestamp: parseInt((new Date()).getTime() / 1000)
		}
	}
	return res
}

async function PullPrice(pairs) {
	return await requestAll(pairs)
}


//(async () => { await requestAll({ "FLOW/USDT":0.0, "BTC/USDT": 0.0 })	})()

module.exports = {
    PullPrice
}