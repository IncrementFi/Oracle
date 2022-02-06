const http = require("./http");

// docs: https://trade-docs.coinlist.co/#symbols
const coinlistURL = "https://trade-api.coinlist.co/v1/symbols/"

function pairFormat(pair) {
	return pair.replace('/', '-')
}

async function requestOne(pair) {
	var url = coinlistURL + pairFormat(pair);
	var respJson
	var resp = await http.request(url)
	try {
		respJson = await resp.json()
	} catch(err) {
		throw( Error("coinlist parse request error["+url+"]") )
	}

	return respJson.symbol
}

async function requestAll(pairs) {
	var respJson = []

	if (Object.keys(pairs).length > 3 ) {
		var resp = await http.request(coinlistURL)
		try {
			respJson = await resp.json().symbols
		} catch {
			throw( Error("coinlist parse request result json error.") )
		}
	} else {
		for (let pair in pairs) {
			respJson.push( await requestOne(pair) )
		}
	}

	var res = await parseResponse(respJson, pairs)
	
	return res
}

async function parseResponse(respJson, pairs) {
	var res = {}
	var respMap = {}
	for (let i = 0; i < respJson.length; ++i) {
		var symbol = respJson[i].symbol
		var price = respJson[i].fair_price
		respMap[symbol] = price
	}

	for (let pair in pairs) {
		var pairWithoutSlash = pairFormat(pair)
		if (!(pairWithoutSlash in respMap)) {
			throw(Error("coinlist pair resp mismatch error: "+pair));
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


(async () => { console.log( await requestAll({ "FLOW/USD":0.0, "BTC/USDT": 0.0 }) ) })()

module.exports = {
    PullPrice
}