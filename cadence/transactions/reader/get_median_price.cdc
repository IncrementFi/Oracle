import OracleInterface from "../../contracts/OracleInterface.cdc"
import OracleConfig from "../../contracts/OracleConfig.cdc"


transaction(oracleAddr: Address) {
    prepare(readerAccount: AuthAccount) {
        log("Transaction Start --------------- get price")
        let oraclePublicInterface_ReaderRef = getAccount(oracleAddr).getCapability<&{OracleInterface.OraclePublicInterface_Reader}>(OracleConfig.OraclePublicInterface_ReaderPath).borrow()
                                              ?? panic("Lost oracle public capability at ".concat(oracleAddr.toString()))

        let priceReaderSuggestedPath = oraclePublicInterface_ReaderRef.getPriceReaderStoragePath()
        
        // mint if non-exist
        if (readerAccount.borrow<&OracleInterface.PriceReader>(from: priceReaderSuggestedPath) == nil) {
            let oraclePublicInterface_ReaderRef = getAccount(oracleAddr).getCapability<&{OracleInterface.OraclePublicInterface_Reader}>(OracleConfig.OraclePublicInterface_ReaderPath).borrow()
                                ?? panic("Lost oracle public capability at ".concat(oracleAddr.toString()))

            let priceReader <- oraclePublicInterface_ReaderRef.mintPriceReader()

            destroy <- readerAccount.load<@AnyResource>(from: priceReaderSuggestedPath)
            readerAccount.save(<- priceReader, to: priceReaderSuggestedPath)
        }


        let priceReaderRef = readerAccount.borrow<&OracleInterface.PriceReader>(from: priceReaderSuggestedPath)
                             ?? panic("Lost local price reader resource.")
        
        let price = priceReaderRef.getMedianPrice()
        
        assert(price > 0.0, message: "Invalid oracle price 0.0")

        log("price: ".concat(price.toString()))

        log("End -----------------------------")
    }
}