import OracleInterface from "../../contracts/OracleInterface.cdc"
import OracleConfig from "../../contracts/OracleConfig.cdc"


transaction(oracleAddr: Address) {
    prepare(readerAccount: AuthAccount) {
        log("Transaction Start --------------- get price")
        let oraclePublicInterface_ReaderRef = getAccount(oracleAddr).getCapability<&{OracleInterface.OraclePublicInterface_Reader}>(OracleConfig.OraclePublicInterface_ReaderPath).borrow()
                                              ?? panic("Lost oracle public capability at ".concat(oracleAddr.toString()))

        let priceReaderSuggestedPath = oraclePublicInterface_ReaderRef.getPriceReaderStoragePath()


        let priceReaderRef = readerAccount.borrow<&OracleInterface.PriceReader>(from: priceReaderSuggestedPath)
                             ?? panic("Lost local price reader resource.")
        
        let price = priceReaderRef.getMedianPrice()
        
        log("price: ".concat(price.toString()))

        log("End -----------------------------")
    }
}