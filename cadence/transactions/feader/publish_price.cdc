import OracleInterface from "../../contracts/OracleInterface.cdc"
import OracleConfig from "../../contracts/OracleConfig.cdc"

transaction(oracleAddr: Address, price: UFix64) {
    prepare(feaderAccount: AuthAccount) {
        log("Transaction Start --------------- set price ".concat(price.toString()).concat(" at ").concat(oracleAddr.toString()))
        
        let oracleFeaderPublicRef = getAccount(oracleAddr).getCapability<&{OracleInterface.OracleFeaderPublic}>(OracleConfig.OracleFeaderPublicPath).borrow()
                              ?? panic("Lost oracle public capability at ".concat(oracleAddr.toString()))

        let pricePanelRef = feaderAccount.borrow<&OracleInterface.FeaderPricePanel>(from: oracleFeaderPublicRef.getPricePanelStoragePath()) ?? panic("Lost feader resource.")

        pricePanelRef.publishPrice(price: price)

        log("End -----------------------------")
    }
}