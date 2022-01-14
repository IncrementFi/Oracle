const http = require("./http");

// docs: https://docs.kraken.com/rest/
const krakenURL = "https://api.kraken.com/0/public/Ticker?pair=";


async function request(pairs) {
	var url = krakenURL;
	var count = 0;
	for (let pair in pairs) {
		url = url + pair
		if (count < Object.keys(pairs).length-1) url = url + ",";
		++count
	}
	//console.log(url)
	
	var resp = await http.request(url)

	var res = {}
	var respJson
	try {
		respJson = await resp.json();
	} catch {
		throw( Error("kraken parse request result json error.") )
	}

	if (respJson.error.length == 0) {
		res = await parseResponse(respJson.result, pairs)
	} else {
		var errorMsg = respJson.error[0];
		throw(Error("kraken request error: "+errorMsg));
	}
	return res
}

async function parseResponse(respJson, pairs) {
	var res = {}
	for (let pair in pairs) {
		if (!(pair in respJson)) {
			throw(Error("kraken pair resp mismatch error: "+pair));
		}
		var ask = respJson[pair]['a'][0]
		var bid = respJson[pair]['b'][0]
		res[pair] = {
			price: (parseFloat(ask) + parseFloat(bid)) / 2,
			timestamp: parseInt((new Date()).getTime() / 1000)
		}
	}
	return res
}

async function PullPrice(pairs) {
	return await request(pairs)
}

//(async () => { console.log( await request({ "FLOW/USD":0.0, "BTC/USDT": 0.0 }) ) })()

module.exports = {
    PullPrice
}