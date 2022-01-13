import OracleInterface from "../../contracts/OracleInterface.cdc"
import OracleConfig from "../../contracts/OracleConfig.cdc"

transaction() {
    prepare(oracleAccount: AuthAccount) {
        log("Transaction Start --------------- del feeder whitelist ")
        
        let oracleAdminRef = oracleAccount.borrow<&{OracleInterface.Admin}>(from: OracleConfig.OracleAdminPath) ?? panic("Lost medianizer admin resource.")

        log(oracleAdminRef.getFeederWhiteListPrice())

        log("End -----------------------------")
    }
}