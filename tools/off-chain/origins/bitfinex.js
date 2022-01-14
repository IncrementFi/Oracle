const http = require("./http");

// docs: https://docs.bitfinex.com/reference#rest-public-platform-status
const bitfinexURL = "https://api-pub.bitfinex.com/v2/tickers?symbols=ALL"
const bitfinexURL_multi = "https://api-pub.bitfinex.com/v2/tickers?symbols=";


const bitfinexConfig = [["AAA","TESTAAA"],["ABS","ABYSS"],["AIO","AION"],["ALG","ALGO"],["AMP","AMPL"],["AMPF0","AMPLF0"],["ATO","ATOM"],["BAB","BCH"],["BBB","TESTBBB"],["CNHT","CNHt"],["CSX","CS"],["CTX","CTXC"],["DAT","DATA"],["DOG","MDOGE"],["DRN","DRGN"],["DSH","DASH"],["DTX","DT"],["EDO","PNT"],["EUS","EURS"],["EUT","EURt"],["GSD","GUSD"],["IOS","IOST"],["IOT","IOTA"],["LBT","LBTC"],["LES","LEO-EOS"],["LET","LEO-ERC20"],["MIT","MITH"],["MNA","MANA"],["NCA","NCASH"],["OMN","OMNI"],["PAS","PASS"],["POY","POLY"],["QSH","QASH"],["QTM","QTUM"],["RBT","RBTC"],["REP","REP2"],["SCR","XD"],["SNG","SNGLS"],["SPK","SPANK"],["STJ","STORJ"],["TSD","TUSD"],["UDC","USDC"],["USK","USDK"],["UST","USDt"],["USTF0","USDt0"],["UTN","UTNP"],["VSY","VSYS"],["WBT","WBTC"],["XAUT","XAUt"],["XCH","XCHF"],["YGG","YEED"],["YYW","YOYOW"]]

function pairFormat(pair) {
	var pairNames = pair.split('/')
	var pair1 = pairNames[0]
	var pair2 = pairNames[1]
	for (let i = 0; i < bitfinexConfig.length; ++i) {
		if (pair1 == bitfinexConfig[i][1].toUpperCase()) {
			pair1 = bitfinexConfig[i][0]
		}
	}
	return "t" + pair1 + pair2
}

async function request(pairs) {
	var url = bitfinexURL_multi;
	var count = 0;
	for (let pair in pairs) {
		
		url = url + pairFormat(pair)
		if (count < Object.keys(pairs).length-1) url = url + ",";
		++count
	}
	
	var resp = await http.request(url)

	var res = {}
	var respJson
	try {
		respJson = await resp.json();
	} catch {
		throw( Error("bitfinex parse request result json error.") )
	}

	if (respJson.length > 0) {
		res = await parseResponse(respJson, pairs)
	} else {
		throw(Error("bitfinex request error"));
	}
	return res
}

async function parseResponse(respJson, pairs) {
	var res = {}
	var respMap = {}
	for (let i = 0; i < respJson.length; ++i) {
		respMap[respJson[i][0]] = respJson[i][1]
	}
	
	for (let pair in pairs) {
		let pairName = pairFormat(pair)
		if (!(pairName in respMap)) {
			throw(Error("bitfinex pair resp mismatch error: "+pair));
		}
		
		
		res[pair] = {
			price: parseFloat(respMap[pairName]),
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
		"BTC/USD": 0.0
	})
})()
*/

module.exports = {
    PullPrice
}