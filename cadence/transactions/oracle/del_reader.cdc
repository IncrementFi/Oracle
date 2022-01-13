import OracleInterface from "../../contracts/OracleInterface.cdc"
import OracleConfig from "../../contracts/OracleConfig.cdc"

transaction(readerAddr: Address) {
    prepare(oracleAccount: AuthAccount) {
        log("Transaction Start --------------- del feeder whitelist ".concat(readerAddr.toString()))
        
        let oracleAdminRef = oracleAccount.borrow<&{OracleInterface.Admin}>(from: OracleConfig.OracleAdminPath) ?? panic("Lost medianizer admin resource.")

        oracleAdminRef.delReaderWhiteList(readerAddr: readerAddr)

        log("End -----------------------------")
    }
}