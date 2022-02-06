const http = require("./http");

// docs: https://www.okex.com/docs-v5/en/#market-maker-program
const okexURL_all = "https://www.okex.com/api/v5/market/tickers?instType=SPOT"
const okexURL_one = "https://www.okex.com/api/v5/market/ticker?instId="

function pairFormat(pair) {
	return pair.replace('/', '-')
}

async function requestOne(pair) {
	var url = okexURL_one + pairFormat(pair);
	var respJson
	var resp = await http.request(url)
	try {
		respJson = await resp.json()
	} catch(err) {
		throw( Error("okex parse request error["+url+"]") )
	}
	if (respJson.code != "0") {
		throw(Error("okex respJson error: "+respJson.msg));
	}
	respJson = respJson.data[0]
	return respJson
}

async function request(pairs) {
	var respJson = []
	if (Object.keys(pairs).length > 3 ) {
		var resp = await http.request(okexURL_all)
		try {
			respJson = await resp.json()
		} catch {
			throw( Error("okex parse request all result json error.") )
		}
		if (respJson.code != "0") {
			throw(Error("okex respJson error: "+respJson.msg));
		}
		respJson = respJson.data

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
		var symbol = respJson[i].instId
		var price = respJson[i].last
		respMap[symbol] = price
	}

	for (let pair in pairs) {
		var pairWithoutSlash = pairFormat(pair)
		if (!(pairWithoutSlash in respMap)) {
			throw(Error("okex pair resp mismatch error: "+pair));
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



//(async () => { console.log( await request({ "FLOW/USDT":0.0, "BTC/USDT": 0.0 }) ) })()


module.exports = {
    PullPrice
}