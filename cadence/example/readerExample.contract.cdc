import OracleInterface from "../contracts/OracleInterface.cdc"
import OracleConfig from "../contracts/OracleConfig.cdc"

/// Steps for being PriceReader
/// 1. Apply for joining reader whitelist for your contract address (contact@increment.fi)
/// 2. Mint the PriceReader resource and save it in your local storage
/// 3. Read price via PriceReader resource

pub contract OraclePriceUseContract {

    pub fun usecase() {
        /// testnet oracle address
        /// hard code for test
        var oracleAddr_flow: Address = 0xcbdb5a7b89c3c844
        var oracleAddr_fusd: Address = 0x3b220a3372190656
        var oracleAddr_blt: Address  = 0x2d766f00eb1d0c37

        let flowPrice = self.getPrice(oracleAddr: oracleAddr_flow)
        let fusdPrice = self.getPrice(oracleAddr: oracleAddr_fusd)
        let bltPrice  = self.getPrice(oracleAddr: oracleAddr_blt)
    }


    pub fun getPrice(oracleAddr: Address): UFix64 {
        /// Recommended storage path for PriceReader resource
        let priceReaderSuggestedPath = getAccount(oracleAddr).getCapability<&{OracleInterface.OraclePublicInterface_Reader}>(OracleConfig.OraclePublicInterface_ReaderPath).borrow()!.getPriceReaderStoragePath()
        ///
        let priceReaderRef  = self.account.borrow<&OracleInterface.PriceReader>(from: priceReaderSuggestedPath)
        if priceReaderRef == nil {
            self.mintPriceReader(oracleAddr: oracleAddr)
        }
        ///
        let price = priceReaderRef!.getMedianPrice()

        return price
    }

    pub fun mintPriceReader(oracleAddr: Address) {
        /// Oracle contract's interface
        let oraclePublicInterface_ReaderRef = getAccount(oracleAddr).getCapability<&{OracleInterface.OraclePublicInterface_Reader}>(OracleConfig.OraclePublicInterface_ReaderPath).borrow()
                                              ?? panic("Lost oracle public capability at ".concat(oracleAddr.toString()))
        /// Recommended storage path for PriceReader resource
        let priceReaderSuggestedPath = oraclePublicInterface_ReaderRef.getPriceReaderStoragePath()

        /// check if already minted
        if (self.account.borrow<&OracleInterface.PriceReader>(from: priceReaderSuggestedPath) == nil) {
            /// price reader resource
            let priceReader <- oraclePublicInterface_ReaderRef.mintPriceReader()

            destroy <- self.account.load<@AnyResource>(from: priceReaderSuggestedPath)
            self.account.save(<- priceReader, to: priceReaderSuggestedPath)
        }
    }

    init() {}

}
 