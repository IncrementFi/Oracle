const http = require("./http");

// docs: https://docs.ftx.com/#rest-api
const ftxURL_all = "https://ftx.com/api/markets"
const ftxURL_one = "https://ftx.com/api/markets/"


async function requestOne(pair) {
	var url = ftxURL_one + pair;
	var respJson
	var resp = await http.request(url)
	try {
		respJson = await resp.json()
	} catch(err) {
		throw( Error("ftx parse request error["+url+"]") )
	}
	if (respJson.success != true) {
		throw(Error("ftx respJson error."));
	}
	return respJson.result
}

async function request(pairs) {
	var respJson = []
	if (Object.keys(pairs).length > 3 ) {
		var resp = await http.request(ftxURL_all)
		try {
			respJson = await resp.json()
		} catch {
			throw( Error("binance parse request result json error.") )
		}
		if (respJson.success != true) {
			throw(Error("ftx respJson error."));
		}
		respJson = respJson.result
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
		var symbol = respJson[i].name
		var price = respJson[i].last
		respMap[symbol] = price
	}

	for (let pair in pairs) {
		var pairWithoutSlash = pair
		if (!(pairWithoutSlash in respMap)) {
			throw(Error("ftx pair resp mismatch error: "+pair));
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


/*
(async () => {
	await request({
		"USDT/USD":0.0,
		"BTC/USDT":0.0
	})	
})()
*/

module.exports = {
    PullPrice
}