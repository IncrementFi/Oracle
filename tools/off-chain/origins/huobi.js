const http = require("./http");

// docs https://huobiapi.github.io/docs/spot/v1/en/#get-latest-tickers-for-all-pairs
const huobiURL_all = "https://api.huobi.pro/market/tickers"
const huobiURL_one = "https://api.huobi.pro/market/detail/merged?symbol="


function pairFormat(pair) {
	return pair.replace('/', '').toLowerCase()
}

async function requestOne(pair) {
	var formatPair = pairFormat(pair)
	var url = huobiURL_one + formatPair
	var respJson
	var resp = await http.request(url)
	try {
		respJson = await resp.json()
	} catch(err) {
		throw( Error("huobi parse request result json error.") )
	}
	if (respJson.status != 'ok' ) {
		throw(Error("huobi respJson error "+respJson.status))
	}

	return {
		"symbol":formatPair,
		"bid":respJson.tick.bid[0],
		"ask":respJson.tick.ask[0]
	}
}
async function requestAll(pairs) {
	var respJson = []
	if (Object.keys(pairs).length > 3 ) {
		var resp = await http.request(huobiURL_all)
		try {
			respJson = await resp.json()
		} catch {
			throw( Error("huobi parse request all result json error.") )
		}
		if (respJson.status != 'ok' ) {
			throw(Error("huobi respJson error: "+respJson.status))
		}
		respJson = respJson.data
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
		var price = (parseFloat(respJson[i].bid) + parseFloat(respJson[i].ask))/2
		respMap[symbol] = price
	}

	for (let pair in pairs) {
		var pairWithoutSlash = pairFormat(pair)
		if (!(pairWithoutSlash in respMap)) {
			throw(Error("huobi pair resp mismatch error: "+pair));
		}
		var price = respMap[pairWithoutSlash]
		res[pair] = {
			price: price,
			timestamp: parseInt((new Date()).getTime() / 1000)
		}
	}
	return res
}

async function PullPrice(pairs) {
	return await requestAll(pairs)
}


//(async () => { console.log( await requestAll({ "FLOW/USDT":0.0, "BTC/USDT": 0.0 }) ) })()

module.exports = {
    PullPrice
}