import OracleInterface from "../../contracts/OracleInterface.cdc"
import OracleConfig from "../../contracts/OracleConfig.cdc"


transaction(oracleAddr: Address) {

    let priceReaderRef: &OracleInterface.PriceReader

    prepare(readerAccount: AuthAccount) {
        /// Oracle public interface capability
        let oraclePublicInterface_ReaderRef = getAccount(oracleAddr).getCapability<&{OracleInterface.OraclePublicInterface_Reader}>(OracleConfig.OraclePublicInterface_ReaderPath).borrow()
                                              ?? panic("Lost oracle public capability at ".concat(oracleAddr.toString()))
        /// Recommended storage path for PriceReader resource
        let priceReaderSuggestedPath = oraclePublicInterface_ReaderRef.getPriceReaderStoragePath()
        
        /// Mint PriceReader if non-exist
        if (readerAccount.borrow<&OracleInterface.PriceReader>(from: priceReaderSuggestedPath) == nil) {
            let priceReader <- oraclePublicInterface_ReaderRef.mintPriceReader()
            destroy <- readerAccount.load<@AnyResource>(from: priceReaderSuggestedPath)
            readerAccount.save(<- priceReader, to: priceReaderSuggestedPath)
        }
        self.priceReaderRef = readerAccount.borrow<&OracleInterface.PriceReader>(from: priceReaderSuggestedPath)
                             ?? panic("Lost local price reader resource.")
        
    }

    execute {
        /// Get median price
        let price = self.priceReaderRef.getMedianPrice()
    }
}