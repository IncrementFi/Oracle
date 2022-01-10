import OracleInterface from "../../contracts/OracleInterface.cdc"
import OracleConfig from "../../contracts/OracleConfig.cdc"

transaction(oracleAddr: Address) {
    prepare(feaderAccount: AuthAccount) {
        log("Transaction Start --------------- init feader ".concat(oracleAddr.toString()))
        
        let oracleFeaderPublicRef = getAccount(oracleAddr).getCapability<&{OracleInterface.OracleFeaderPublic}>(OracleConfig.OracleFeaderPublicPath).borrow()
                              ?? panic("Lost oracle public capability at ".concat(oracleAddr.toString()))

        let pricePanel <- oracleFeaderPublicRef.mintFeaderPricePanel()

        feaderAccount.save(<- pricePanel, to: oracleFeaderPublicRef.getPricePanelStoragePath())
        feaderAccount.link<&{OracleInterface.FeaderPricePanelPublic}>(oracleFeaderPublicRef.getPricePanelPublicPath(), target: oracleFeaderPublicRef.getPricePanelStoragePath())

        log("End -----------------------------")
    }
}