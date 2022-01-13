import OracleInterface from "../../contracts/OracleInterface.cdc"
import OracleConfig from "../../contracts/OracleConfig.cdc"


transaction(
    priceIdentifier: String,
    minFeederNumber: Int,
    feederStoragePath: StoragePath,
    feederPublicPath: PublicPath,
    readerStoragePath: StoragePath
) {
    prepare(oracleAccount: AuthAccount) {
        log("Transaction Start --------------- init oracle ".concat(priceIdentifier))
        
        let oracleAdminRef = oracleAccount.borrow<&{OracleInterface.Admin}>(from: OracleConfig.OracleAdminPath) ?? panic("Lost oracle admin resource.")

        oracleAdminRef.configOracle(
            priceIdentifier: priceIdentifier,
            minFeederNumber: minFeederNumber,
            feederStoragePath: feederStoragePath,
            feederPublicPath: feederPublicPath,
            readerStoragePath: readerStoragePath
        )

        log("End -----------------------------")
    }
}