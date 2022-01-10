import OracleInterface from "../../contracts/OracleInterface.cdc"
import OracleConfig from "../../contracts/OracleConfig.cdc"


transaction(
    tokenTypeIdentifier: String,
    minFeaderNumber: Int,
    feaderStoragePath: StoragePath,
    feaderPublicPath: PublicPath
) {
    prepare(oracleAccount: AuthAccount) {
        log("Transaction Start --------------- init oracle ".concat(tokenTypeIdentifier))
        
        let oracleAdminRef = oracleAccount.borrow<&{OracleInterface.Admin}>(from: OracleConfig.OracleAdminPath) ?? panic("Lost oracle admin resource.")

        oracleAdminRef.configOracle(
            tokenTypeIdentifier: tokenTypeIdentifier,
            minFeaderNumber: minFeaderNumber,
            feaderStoragePath: feaderStoragePath,
            feaderPublicPath: feaderPublicPath
        )

        log("End -----------------------------")
    }
}