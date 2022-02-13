import OracleInterface from "../../contracts/OracleInterface.cdc"
import OracleConfig from "../../contracts/OracleConfig.cdc"

transaction(oracleAddr: Address, expireDuration: UInt64) {
    prepare(feederAccount: AuthAccount) {
        log("Transaction Start --------------- set expire time")
        
        let oraclePublicInterface_FeederRef = getAccount(oracleAddr).getCapability<&{OracleInterface.OraclePublicInterface_Feeder}>(OracleConfig.OraclePublicInterface_FeederPath).borrow()
                              ?? panic("Lost oracle public capability at ".concat(oracleAddr.toString()))
        // mint PriceFeeder if non-exist
        if (feederAccount.borrow<&OracleInterface.PriceFeeder>(from: oraclePublicInterface_FeederRef.getPriceFeederStoragePath()) == nil) {
            let priceFeeder <- oraclePublicInterface_FeederRef.mintPriceFeeder()

            destroy <- feederAccount.load<@AnyResource>(from: oraclePublicInterface_FeederRef.getPriceFeederStoragePath())
            feederAccount.save(<- priceFeeder, to: oraclePublicInterface_FeederRef.getPriceFeederStoragePath())
            feederAccount.link<&{OracleInterface.PriceFeederPublic}>(oraclePublicInterface_FeederRef.getPriceFeederPublicPath(), target: oraclePublicInterface_FeederRef.getPriceFeederStoragePath())
        }
        let priceFeederRef = feederAccount.borrow<&OracleInterface.PriceFeeder>(from: oraclePublicInterface_FeederRef.getPriceFeederStoragePath()) ?? panic("Lost feeder resource.")

        priceFeederRef.setExpriedDuration(blockheightDuration: expireDuration)

        log("End -----------------------------")
    }
}