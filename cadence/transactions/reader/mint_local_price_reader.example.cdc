import OracleInterface from "../../contracts/OracleInterface.cdc"
import OracleConfig from "../../contracts/OracleConfig.cdc"

transaction(oracleAddr: Address) {
    prepare(readerAccount: AuthAccount) {
        /// Oracle public interface capability
        let oraclePublicInterface_ReaderRef = getAccount(oracleAddr).getCapability<&{OracleInterface.OraclePublicInterface_Reader}>(OracleConfig.OraclePublicInterface_ReaderPath).borrow()
                                              ?? panic("Lost oracle public capability at ".concat(oracleAddr.toString()))
        /// Recommended storage path for PriceReader resource
        let priceReaderSuggestedPath = oraclePublicInterface_ReaderRef.getPriceReaderStoragePath()

        /// check if already minted
        if (readerAccount.borrow<&OracleInterface.PriceReader>(from: priceReaderSuggestedPath) == nil) {
            let priceReader <- oraclePublicInterface_ReaderRef.mintPriceReader()

            destroy <- readerAccount.load<@AnyResource>(from: priceReaderSuggestedPath)
            readerAccount.save(<- priceReader, to: priceReaderSuggestedPath)
        }
    }
}