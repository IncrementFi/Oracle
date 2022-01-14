const config = require('../config');

const FCL = require('@onflow/fcl');
FCL.config().put("accessNode.api", config.rpc[config.domain].accessNode)
const T = require('@onflow/types');
const UTILS = require('./FlowUtils')

const path = require('path');
const dotenv = require('dotenv')
dotenv.config({path:path.resolve(__dirname, '../.env')})

const auditAddr = config.comptrollerAddr

var feederAddr = process.env[config.domain+"FeederAddr"]
var feederPrivateKey = process.env[config.domain+"FeederPrivateKey"]
//var feederAddr = "0xe03daebed8ca0615"
//var feederPrivateKey = "14b15e83fc8b1725e1f949fd9770041ed35631c3035aa569654f9f795674f782"

const keyConfig = {
    account: feederAddr,
    keyIndex: 0,
    privateKey: feederPrivateKey,
    SequenceNumber: 0
};


async function publishPrice(priceName, price) {
    price = (parseFloat(price)*1.000).toFixed(8).toString()
    let domain = config.domain
    let oracleAddr = config.prices[priceName].oracleAddr[domain]
    
    const myAuth = UTILS.authFunc(keyConfig);
    FCL.config()

    var CODE = "import OracleInterface from " + config.contractAddr[config.domain].OracleInterface + "\n" +
               "import OracleConfig from " + config.contractAddr[config.domain].OracleConfig + "\n" +
               "transaction(oracleAddr: Address, price: UFix64) { \n\
                    prepare(feederAccount: AuthAccount) { \n\
                        let oraclePublicInterface_FeederRef = getAccount(oracleAddr).getCapability<&{OracleInterface.OraclePublicInterface_Feeder}>(OracleConfig.OraclePublicInterface_FeederPath).borrow() \n\
                                          ?? panic(\"Lost oracle public capability at \".concat(oracleAddr.toString())) \n\
                        let pricePanelRef = feederAccount.borrow<&OracleInterface.PriceFeeder>(from: oraclePublicInterface_FeederRef.getPriceFeederStoragePath()) ?? panic(\"Lost feeder resource.\") \n\
                        pricePanelRef.publishPrice(price: price) \n\
                    }\n\
                }"

    const response = await FCL.send([
        FCL.transaction`
        ${CODE}
        `,
        FCL.args([
            FCL.arg(oracleAddr, T.Address),
            FCL.arg(price, T.UFix64)
        ]),
        FCL.proposer(myAuth),
        FCL.authorizations([myAuth]),
        FCL.payer(myAuth),
        FCL.limit(9999),
    ]);
    return await FCL.tx(response).onceSealed();
}


module.exports = {
    publishPrice
}