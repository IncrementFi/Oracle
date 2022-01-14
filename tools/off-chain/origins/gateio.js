const http = require("./http");

// docs: https://www.gate.io/docs/apiv4/en/#get-details-of-a-specifc-order
const gateio_one = "https://fx-api.gateio.ws/api/v4/spot/tickers?currency_pair="
const gateio_all = "https://fx-api.gateio.ws/api/v4/spot/tickers"

function pairFormat(pair) {
	return pair.replace('/', '_')
}

async function requestOne(pair) {
	var url = gateio_one + pairFormat(pair);
	var respJson
	var resp = await http.request(url)
	try {
		respJson = await resp.json()
	} catch(err) {
		throw( Error("gateio parse request result json error.") )
	}
	if (respJson.length == 0) {
		throw(Error("gateio respJson error"));
	}
	respJson = respJson[0]
	return respJson
}

async function request(pairs) {
	var respJson = []
	if (Object.keys(pairs).length > 3 ) {
		var resp = await http.request(gateio_all)
		try {
			respJson = await resp.json()
		} catch {
			throw( Error("gateio parse request all result json error.") )
		}
		if (respJson.length == 0) {
			throw(Error("gateio respJson error"));
		}

	} else {
		for (let pair in pairs) {
			respJson.push( await requestOne(pair) )
		}
	}

	var	res = await parseResponse(respJson, pairs)
	return res
}

async function parseResponse(respJson, pairs) {
	var res = {}
	var respMap = {}
	for (let i = 0; i < respJson.length; ++i) {
		var symbol = respJson[i].currency_pair
		var price = (parseFloat(respJson[i].highest_bid) + parseFloat(respJson[i].lowest_ask)) / 2
		respMap[symbol] = price
	}

	for (let pair in pairs) {
		var pairWithoutSlash = pairFormat(pair)
		if (!(pairWithoutSlash in respMap)) {
			throw(Error("gateio pair resp mismatch error: "+pair));
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
	return await request(pairs)
}



//(async () => { console.log( await request({ "BLT/USDT":0.0, "BTC/USDT": 0.0 }) ) })()


module.exports = {
    PullPrice
}