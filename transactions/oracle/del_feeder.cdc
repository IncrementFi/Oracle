import OracleInterface from "../../contracts/OracleInterface.cdc"
import OracleConfig from "../../contracts/OracleConfig.cdc"

transaction(feederAddr: Address) {
    prepare(oracleAccount: AuthAccount) {
        let oracleAdminRef = oracleAccount.borrow<&{OracleInterface.Admin}>(from: OracleConfig.OracleAdminPath) ?? panic("Lost medianizer admin resource.")
        oracleAdminRef.delFeederWhiteList(feederAddr: feederAddr)
    }
}
