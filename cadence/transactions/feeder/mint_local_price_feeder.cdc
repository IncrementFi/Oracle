import OracleInterface from "../../contracts/OracleInterface.cdc"
import OracleConfig from "../../contracts/OracleConfig.cdc"

transaction(oracleAddr: Address) {
    prepare(feederAccount: AuthAccount) {
        log("Transaction Start --------------- init feeder ".concat(oracleAddr.toString()))
        
        let oraclePublicInterface_FeederRef = getAccount(oracleAddr).getCapability<&{OracleInterface.OraclePublicInterface_Feeder}>(OracleConfig.OraclePublicInterface_FeederPath).borrow()
                              ?? panic("Lost oracle public capability at ".concat(oracleAddr.toString()))

        let pricePanel <- oraclePublicInterface_FeederRef.mintPriceFeeder()

        feederAccount.save(<- pricePanel, to: oraclePublicInterface_FeederRef.getPriceFeederStoragePath())
        feederAccount.link<&{OracleInterface.PriceFeederPublic}>(oraclePublicInterface_FeederRef.getPriceFeederPublicPath(), target: oraclePublicInterface_FeederRef.getPriceFeederStoragePath())

        log("End -----------------------------")
    }
}