import OracleInterface from "../../contracts/OracleInterface.cdc"
import OracleConfig from "../../contracts/OracleConfig.cdc"


transaction(oracleAddr: Address) {
    prepare(readerAccount: AuthAccount) {
        log("Transaction Start --------------- get price")
        let readerCertificateRef = readerAccount.borrow<&OracleInterface.ReaderCertificate>(from: OracleConfig.ReaderCertificateStoragePath)
                                     ?? panic("Please apply for the reader certificate first.")
        let oracleReaderPublicRef = getAccount(oracleAddr).getCapability<&{OracleInterface.OracleReaderPublic}>(OracleConfig.OracleReaderPublicPath).borrow()
                              ?? panic("Lost oracle public capability at ".concat(oracleAddr.toString()))
                              
        let price = oracleReaderPublicRef.getMedianPrice(readerCertificate: readerCertificateRef)
        
        log("price: ".concat(price.toString()))

        log("End -----------------------------")
    }
}