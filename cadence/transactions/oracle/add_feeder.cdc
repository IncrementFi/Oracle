import OracleInterface from "../../contracts/OracleInterface.cdc"
import OracleConfig from "../../contracts/OracleConfig.cdc"

transaction(feederAddr: Address) {
    prepare(oracleAccount: AuthAccount) {
        log("Transaction Start --------------- add feeder whitelist ".concat(feederAddr.toString()))
        
        let oracleAdminRef = oracleAccount.borrow<&{OracleInterface.Admin}>(from: OracleConfig.OracleAdminPath) ?? panic("Lost medianizer admin resource.")

        oracleAdminRef.addFeederWhiteList(feederAddr: feederAddr)

        log("End -----------------------------")
    }
}