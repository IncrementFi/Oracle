import OracleInterface from "../../contracts/OracleInterface.cdc"
import OracleConfig from "../../contracts/OracleConfig.cdc"

transaction(feaderAddr: Address) {
    prepare(oracleAccount: AuthAccount) {
        log("Transaction Start --------------- add feader whitelist ".concat(feaderAddr.toString()))
        
        let oracleAdminRef = oracleAccount.borrow<&{OracleInterface.Admin}>(from: OracleConfig.OracleAdminPath) ?? panic("Lost medianizer admin resource.")

        oracleAdminRef.addFeaderWhiteList(feaderAddr: feaderAddr)

        log("End -----------------------------")
    }
}