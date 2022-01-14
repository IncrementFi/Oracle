const fetch = require('node-fetch');
const httpsProxyAgent = require('https-proxy-agent');
const config = require('../config.json');

async function request(url) {
	var resp = {};
	try {
		if (config.domain == "emulator") {
			resp = await fetch(url,
				{
					method: 'GET',
					timeout: 10000,
					agent: new httpsProxyAgent("http://127.0.0.1:7890")
				}
			);
		} else {
			resp = await fetch(url,
				{
					method: 'GET',
					timeout: 1
				}
			);
		}
	} catch (err) {
		throw(err)
	}
	return resp
}

module.exports = {
	request
}