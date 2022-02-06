const http = require("./http");

// const coinbaseURL = "https://coinbase.com/api/markets"
const coinbaseURL_one = "https://api.pro.coinbase.com/products/"


async function requestOne(pair) {
	var pairParam = pair.replace('/', '-')
	var url = coinbaseURL_one + pairParam + "/ticker";

	var resp = await http.request(url)

	var res = {}
	var respJson
	try {
		respJson = await resp.json();
	} catch {
		throw( Error("coinbase parse request error["+url+"]") )
	}
	
	return respJson
}

async function requestAll(pairs) {
	var allResponse = {}
	for (let pair in pairs) {
		var pairRes = await requestOne(pair);
		allResponse[pair] = pairRes
	}

	res = await parseResponse(allResponse, pairs)

	return res
}

async function parseResponse(respJson, pairs) {
	var res = {}
	var respMap = respJson
	
	for (let pair in pairs) {
		var pairWithoutSlash = pair
		if (!(pairWithoutSlash in respMap)) {
			throw(Error("coinbase pair resp mismatch error: "+pair));
		}
		var price = respMap[pairWithoutSlash].price
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


/*
(async () => {
	await requestAll({
		"USDT/USD":0.0,
		"BTC/USDT":0.0
	})	
})()
*/

module.exports = {
    PullPrice
}