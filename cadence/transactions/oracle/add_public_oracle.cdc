import OracleInterface from "../../contracts/OracleInterface.cdc"
import OracleConfig from "../../contracts/OracleConfig.cdc"
import PublicPriceOracle from "../../contracts/PublicPriceOracle.cdc"

transaction(oracleAddr: Address) {
    prepare(oracleAccount: auth(BorrowValue) &Account) {
        var adminRef = oracleAccount.storage.borrow<&PublicPriceOracle.Admin>(from: PublicPriceOracle.OracleAdminStoragePath)!
        adminRef.addOracle(oracleAddr: oracleAddr)
    }
}