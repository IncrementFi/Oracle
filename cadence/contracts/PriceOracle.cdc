/**
  * @Desc This contract is the interface description of PriceOracle.
  *  The oracle includes an medianizer, which obtains prices from multiple feeds and calculate the median as the final price.
  * 
  * @Author Increment Labs
  *
  *  The contract will accept price offers from multiple feeds.
  *  Feeders are anonymous for now to protect the providers from extortion.
  *  We welcome more price-feeding institutions and partners to join in and build a more decentralized oracle on flow.
  *
  *  Currently, the use of this oracle is limited to addresses in the whitelist, and applications can be submitted to Increment Labs.
  *
  * @Concepts
  *  Feed1(off-chain) --> PricePanel(resource) ---- 3.4 ---->
  *  Feed2(off-chain) --> PricePanel(resource) ---- 3.2 ----> PriceOracle(contract) ->  Medianizer -> 3.4 -----> Readers
  *  Feed3(off-chain) --> PricePanel(resource) ---- 3.6 ---->
*/

import OracleInterface from "./OracleInterface.cdc"
import OracleConfig from "./OracleConfig.cdc"

pub contract PriceOracle: OracleInterface {

    // The identifier of the token type, eg: BTC/USD
    pub var _PriceIdentifier: String?

    // Storage path of local oracle certificate
    pub let _CertificateStoragePath: StoragePath
    // Storage path of public interface resource
    pub let _OraclePublicStoragePath: StoragePath

    // The contract will fetch the price according to this path on the feed node
    pub var _FeaderPricePanelPublicPath: PublicPath?
    pub var _FeaderPricePanelStoragePath: StoragePath?

    // Address white list of feeders and readers
    access(self) let _FeaderWhiteList: {Address: Bool}
    access(self) let _ReaderWhiteList: {Address: Bool}

    // The minimum number of feeders to provide a valid price.
    pub var _MinFeaderNumber: Int

    // events
    pub event PublishOraclePrice(price: UFix64, tokenType: String, feaderAddr: Address)
    pub event ReaderCertificateApplication()
    pub event ConfigOracle(oldType: String?, newType: String?, oldMinFeaderNumber: Int, newMinFeaderNumber: Int)
    pub event AddFeaderWhiteList(addr: Address)
    pub event DelFeaderWhiteList(addr: Address)
    pub event AddReaderWhiteList(addr: Address)
    pub event DelReaderWhiteList(addr: Address)


    // @Desc Panel for publishing price. Every feeder needs to mint this resource locally.
    pub resource FeaderPricePanel: OracleInterface.FeaderPricePanelPublic {
        
        access(self) var _Price: UFix64
        access(self) let _PriceIdentifier: String

        // @Desc The feeder uses this function to offer price at the price panel
        // @Param price - price from off-chain
        pub fun publishPrice(price: UFix64) {
            self._Price = price

            emit PublishOraclePrice(price: price, tokenType: PriceOracle._PriceIdentifier!, feaderAddr: self.owner!.address)
        }

        // @Desc Get the current feed price, this function can only be called by the PriceOracle contract
        pub fun fetchPrice(certificate: &OracleInterface.OracleCertificate): UFix64 {
            pre {
                certificate.getType() == Type<@OracleCertificate>(): "PriceOracle certificate does not match."
            }
            return self._Price
        }

        init() {
            self._Price = 0.0
            self._PriceIdentifier = PriceOracle._PriceIdentifier!
        }
    }

    // @Desc All external interfaces of this contract
    pub resource OraclePublic: OracleInterface.OracleReaderPublic, OracleInterface.OracleFeaderPublic {
        
        // @Desc Get the median price of all current feeds.
        // @Param ReaderCertificate - The caller needs to provide a reader certificate
        // @Return Median price, returns 0.0 if the current price is invalid
        pub fun getMedianPrice(readerCertificate: &OracleInterface.ReaderCertificate): UFix64 {
            pre {
                readerCertificate.owner != nil: "Certificate resource must be stored in local storage."
                PriceOracle._ReaderWhiteList.containsKey(readerCertificate.owner!.address): "Reader is not on the whitelist."
            }

            let priceMedian = PriceOracle.takeMedianPrice()

            return priceMedian
        }

        // @Desc Apply for a certificate of reader
        // @Return Resource of certificate - This resource must be stored in local storage
        //  and kept for yourself. Please do not expose the capability to others.
        pub fun applyReaderCertificate(): @OracleInterface.ReaderCertificate {
            emit ReaderCertificateApplication()

            return <- create ReaderCertificate()
        }

        // @Desc Feaders need to mint their own price panels and expose the exact public path to oralce contract
        // @Return Resource of price panel
        pub fun mintFeaderPricePanel(): @FeaderPricePanel {
            return <- create FeaderPricePanel()
        }

        // @Desc The oracle contract will get the feeding-price based on this path
        // Feeders need to expose their price panel capabilities at this public path
        pub fun getPricePanelStoragePath(): StoragePath { return PriceOracle._FeaderPricePanelStoragePath! }
        pub fun getPricePanelPublicPath(): PublicPath { return PriceOracle._FeaderPricePanelPublicPath! }
    }

    // @Desc Each oracle contract will hold its own certificate to identify itself.
    // Only the oracle contract can mint the certificate.
    pub resource OracleCertificate: OracleInterface.IdentityCertificate {}

    // @Desc Reader certificate is used to provide proof of its address.In fact, anyone can mint their reader certificate.
    // Readers only need to apply for a certificate to any oracle contract once.
    // The contract will control the read permission of the readers according to the address whitelist.
    // Please do not share your certificate capability with others and take the responsibility of community governance.
    pub resource ReaderCertificate: OracleInterface.IdentityCertificate {}

    // @Desc Calculate the median price
    // @Return median price
    access(contract) fun takeMedianPrice(): UFix64 {
        let oraclePrices: [UFix64] = []
        let certificateRef = self.account.borrow<&OracleCertificate>(from: self._CertificateStoragePath)
                             ?? panic("Lost PriceOracle certificate resource.")

        var priceList: [UFix64] = []
        var sortList: [UFix64] = []

        for oracleAddr in self._FeaderWhiteList.keys {
            let pricePanelCap = getAccount(oracleAddr).getCapability<&{OracleInterface.FeaderPricePanelPublic}>(PriceOracle._FeaderPricePanelPublicPath!)
            // Get valid feeding-price
            if (pricePanelCap.check()) {
                let price = pricePanelCap.borrow()!.fetchPrice(certificate: certificateRef)
                if(price > 0.0) {
                    priceList.append(price)
                    sortList.append(0.0)
                }
            }
        }

        let len = priceList.length
        // If the number of valid prices is insufficient
        if (len < self._MinFeaderNumber) {
            return 0.0
        }
        // sort
        var i = 0
        while(i < len) {
            let v = priceList[i]
            if (i == 0 || v >= sortList[i-1]) {
                sortList[i] = v
            } else {
                var j = 0
                while (v >= sortList[j]) {
                    j = j + 1
                }
                var k = i
                while(k > j) {
                    sortList[k] = sortList[k-1]
                    k = k - 1
                }
                sortList[j] = v
            }
            
            i = i + 1
        }
        // find median
        var mid = 0.0
        if (len % 2 == 0) {
            let v1 = sortList[len/2-1]
            let v2 = sortList[len/2]
            mid = UFix64(v1+v2)/2.0
        } else {
            mid = sortList[(len-1)/2]
        }

        return mid
         
    }

    access(contract) fun getFeaderWhiteListPrice(): [UFix64] {
            let certificateRef = self.account.borrow<&OracleCertificate>(from: self._CertificateStoragePath)
                             ?? panic("Lost PriceOracle certificate resource.")
            var priceList: [UFix64] = []
            
            for oracleAddr in PriceOracle._FeaderWhiteList.keys {
                let pricePanelCap = getAccount(oracleAddr).getCapability<&{OracleInterface.FeaderPricePanelPublic}>(PriceOracle._FeaderPricePanelPublicPath!)
                if (pricePanelCap.check()) {
                    let price = pricePanelCap.borrow()!.fetchPrice(certificate: certificateRef)
                    if(price > 0.0) {
                        priceList.append(price)
                    } else {
                        priceList.append(0.0)
                    }
                } else {
                    priceList.append(0.0)
                }
            }
            return priceList
        }

    

    access(contract) fun configOracle(
        priceIdentifier: String,
        minFeaderNumber: Int,
        feaderStoragePath: StoragePath,
        feaderPublicPath: PublicPath
    ) {
        emit ConfigOracle(
            oldType: self._PriceIdentifier,
            newType: priceIdentifier,
            oldMinFeaderNumber: self._MinFeaderNumber,
            newMinFeaderNumber: minFeaderNumber
        )

        self._PriceIdentifier = priceIdentifier
        self._MinFeaderNumber = minFeaderNumber
        self._FeaderPricePanelStoragePath = feaderStoragePath
        self._FeaderPricePanelPublicPath = feaderPublicPath
    }


    // @Desc Community administrator, Increment Labs will then collect community feedback and initiate voting for governance.
    pub resource Admin: OracleInterface.Admin {
        // 
        pub fun configOracle(
            priceIdentifier: String,
            minFeaderNumber: Int,
            feaderStoragePath: StoragePath,
            feaderPublicPath: PublicPath
        ) {
            PriceOracle.configOracle(
                priceIdentifier: priceIdentifier,
                minFeaderNumber: minFeaderNumber,
                feaderStoragePath: feaderStoragePath,
                feaderPublicPath: feaderPublicPath
            )
        }

        pub fun addFeaderWhiteList(feaderAddr: Address) {
            // Check if feader prepared price panel first
            let FeaderPricePanelCap = getAccount(feaderAddr).getCapability<&{OracleInterface.FeaderPricePanelPublic}>(PriceOracle._FeaderPricePanelPublicPath!)
            assert(FeaderPricePanelCap.check(), message: "Need to prepare data feader resource capability first.")

            PriceOracle._FeaderWhiteList[feaderAddr] = true

            emit AddFeaderWhiteList(addr: feaderAddr)
        }

        pub fun addReaderWhiteList(readerAddr: Address) {
            
            PriceOracle._ReaderWhiteList[readerAddr] = true

            emit AddReaderWhiteList(addr: readerAddr)
        }

        pub fun delFeaderWhiteList(feaderAddr: Address) {

            PriceOracle._FeaderWhiteList.remove(key: feaderAddr)

            emit DelFeaderWhiteList(addr: feaderAddr)
        }

        pub fun delReaderWhiteList(readerAddr: Address) {

            PriceOracle._ReaderWhiteList.remove(key: readerAddr)

            emit DelReaderWhiteList(addr: readerAddr)
        }

        pub fun getFeaderWhiteList(): [Address] {
            return PriceOracle._FeaderWhiteList.keys
        }

        pub fun getReaderWhiteList(): [Address] {
            return PriceOracle._ReaderWhiteList.keys
        }

        pub fun getFeaderWhiteListPrice(): [UFix64] {
            return PriceOracle.getFeaderWhiteListPrice()
        }
    }


    init() {
        self._FeaderWhiteList = {}
        self._ReaderWhiteList = {}
        self._MinFeaderNumber = 1
        self._PriceIdentifier = nil

        self._CertificateStoragePath = /storage/oracle_certificate
        self._OraclePublicStoragePath = /storage/oralce_public
        
        self._FeaderPricePanelStoragePath = nil
        self._FeaderPricePanelPublicPath = nil
        

        
        // Local admin resource
        self.account.save(<-create Admin(), to: OracleConfig.OracleAdminPath)
        // Create oracle ceritifcate
        self.account.save(<-create OracleCertificate(), to: self._CertificateStoragePath)
        // Public interface
        self.account.save(<-create OraclePublic(), to: self._OraclePublicStoragePath)
        self.account.link<&{OracleInterface.OracleReaderPublic}>(OracleConfig.OracleReaderPublicPath, target: self._OraclePublicStoragePath)
        self.account.link<&{OracleInterface.OracleFeaderPublic}>(OracleConfig.OracleFeaderPublicPath, target: self._OraclePublicStoragePath)
    }
}