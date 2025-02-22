/**

# This contract is the interface description of PriceOracle.
  The oracle includes an medianizer, which obtains prices from multiple feeds and calculate the median as the final price.

# Structure 
  Feeder1(off-chain) --> PriceFeeder(resource) 3.4$                                               PriceReader1(resource)
  Feeder2(off-chain) --> PriceFeeder(resource) 3.2$ --> PriceOracle(contract) cal median 3.4$ --> PriceReader2(resource)
  Feeder3(off-chain) --> PriceFeeder(resource) 3.6$                                               PriceReader3(resource)

# Robustness
  1. Median value is the current aggregation strategy.
  2. _MinFeederNumber determines the minimum number of feeds required to provide a valid price. As long as there're more than 50% of the nodes are honest the median data is trustworthy.
  3. The feeder needs to set a price expiration time, after which the price will be invalid (0.0). Dev is responsible to detect and deal with this abnormal data in the contract logic.

#  More price-feeding institutions and partners are welcome to join and build a more decentralized oracle on flow.
#  To apply to join the Feeder whitelist, please follow: https://docs.increment.fi/protocols/decentralized-price-feed-oracle/apply-as-feeder
#  On-chain price data can be publicly & freely accessed through the PublicPriceOracle contract.

# Author Increment Labs

*/

import OracleInterface from "./OracleInterface.cdc"
import OracleConfig from "./OracleConfig.cdc"

access(all) contract PriceOracle: OracleInterface {

    /// The identifier of the token type, eg: BTC/USD
    access(all) var _PriceIdentifier: String?

    /// Storage path of local oracle certificate
    access(all) let _CertificateStoragePath: StoragePath
    /// Storage path of public interface resource
    access(all) let _OraclePublicStoragePath: StoragePath

    /// The contract will fetch the price according to this path on the feed node
    access(all) var _PriceFeederPublicPath: PublicPath?
    access(all) var _PriceFeederStoragePath: StoragePath?
    /// Recommended path for PriceReader, users can manage resources by themselves
    access(all) var _PriceReaderStoragePath: StoragePath?

    /// Address white list of feeders and readers
    access(self) let _FeederWhiteList: {Address: Bool}
    access(self) let _ReaderWhiteList: {Address: Bool}

    /// The minimum number of feeders to provide a valid price.
    access(all) var _MinFeederNumber: Int

    /// Reserved parameter fields: {ParamName: Value}
    access(self) let _reservedFields: {String: AnyStruct}

    /// events
    access(all) event PublishOraclePrice(price: UFix64, tokenType: String, feederAddr: Address)
    access(all) event MintPriceReader()
    access(all) event MintPriceFeeder()
    access(all) event ConfigOracle(oldType: String?, newType: String?, oldMinFeederNumber: Int, newMinFeederNumber: Int)
    access(all) event AddFeederWhiteList(addr: Address)
    access(all) event DelFeederWhiteList(addr: Address)
    access(all) event AddReaderWhiteList(addr: Address)
    access(all) event DelReaderWhiteList(addr: Address)


    /// Oracle price reader, users need to save this resource in their local storage
    ///
    /// Only readers in the addr whitelist have permission to read prices
    /// Please do not share your PriceReader capability with others and take the responsibility of community governance.
    ///
    access(all) resource PriceReader: OracleInterface.PriceReader {
        access(all) let _PriceIdentifier: String

        /// Get the median price of all current feeds.
        ///
        /// @Return Median price, returns 0.0 if the current price is invalid
        ///
        access(all) view fun getMedianPrice(): UFix64 {
            pre {
                self.owner != nil: "PriceReader resource must be stored in local storage."
                PriceOracle._ReaderWhiteList.containsKey(self.owner!.address): "Reader addr is not on the whitelist."
            }

            let priceMedian = PriceOracle.takeMedianPrice()

            return priceMedian
        }

        access(all) view fun getPriceIdentifier(): String {
            return self._PriceIdentifier
        }

        access(all) view fun getRawMedianPrice(): UFix64 {
            return PriceOracle.getRawMedianPrice()
        }

        access(all) view fun getRawMedianBlockHeight(): UInt64 {
            return PriceOracle.getRawMedianBlockHeight()
        }

        init() {
            self._PriceIdentifier = PriceOracle._PriceIdentifier!
        }
    }

    /// Panel for publishing price. Every feeder needs to mint this resource locally.
    ///
    /// TODO: to confirm if contract can be upgraded with change: `OracleInterface.PriceFeederPublic -> OracleInterface.PriceFeeder`
    access(all) resource PriceFeeder: OracleInterface.PriceFeeder {
        access(self) var _Price: UFix64
        access(self) var _LastPublishBlockHeight: UInt64
        /// seconds
        access(self) var _ExpiredDuration: UInt64

        access(all) let _PriceIdentifier: String

        /// The feeder uses this function to offer price at the price panel
        ///
        /// @Param price - price from off-chain
        ///
        access(OracleInterface.FeederAuth) fun publishPrice(price: UFix64) {
            self._Price = price
            
            self._LastPublishBlockHeight = getCurrentBlock().height
            emit PublishOraclePrice(price: price, tokenType: PriceOracle._PriceIdentifier!, feederAddr: self.owner!.address)
        }

        /// Set valid duration of price. If there is no update within the duration, the price will expire.
        ///
        /// @Param blockheightDuration by the block numbers
        ///
        access(OracleInterface.FeederAuth) fun setExpiredDuration(blockheightDuration: UInt64) {
            self._ExpiredDuration = blockheightDuration
        }

        /// Get the current feed price, returns 0 if the data is expired.
        /// This function can only be called by the PriceOracle contract
        ///
        access(all) view fun fetchPrice(certificate: &{OracleInterface.OracleCertificate}): UFix64 {
            pre {
                certificate.getType() == Type<@OracleCertificate>(): "PriceOracle certificate does not match."
            }
            if (getCurrentBlock().height - self._LastPublishBlockHeight > self._ExpiredDuration) {
                return 0.0
            }
            return self._Price
        }

        /// Get the current feed price regardless of whether it's expired or not.
        ///
        access(all) view fun getRawPrice(certificate: &{OracleInterface.OracleCertificate}): UFix64 {
            pre {
                certificate.getType() == Type<@OracleCertificate>(): "PriceOracle certificate does not match."
            }
            return self._Price
        }

        access(all) view fun getLatestPublishBlockHeight(): UInt64 {
            return self._LastPublishBlockHeight
        }

        access(all) view fun getExpiredHeightDuration(): UInt64 {
            return self._ExpiredDuration
        }

        init() {
            self._Price = 0.0
            self._PriceIdentifier = PriceOracle._PriceIdentifier!
            self._LastPublishBlockHeight = 0
            self._ExpiredDuration = 60 * 40
        }
    }

    /// All external interfaces of this contract
    ///
    access(all) resource OraclePublic: OracleInterface.OraclePublicInterface_Reader, OracleInterface.OraclePublicInterface_Feeder {
        /// Users who need to read the oracle price should mint this resource and save locally.
        ///
        access(all) fun mintPriceReader(): @PriceReader {
            emit MintPriceReader()

            return <- create PriceReader()
        }

        /// Feeders need to mint their own price panels and expose the exact public path to oracle contract
        ///
        /// @Return Resource of price panel
        ///
        access(all) fun mintPriceFeeder(): @{OracleInterface.PriceFeeder} {
            emit MintPriceFeeder()

            return <- create PriceFeeder()
        }

        /// Recommended path for PriceReader, users can manage resources by themselves
        ///
        access(all) view fun getPriceReaderStoragePath(): StoragePath { return PriceOracle._PriceReaderStoragePath! }

        /// The oracle contract will get the feeding-price based on this path
        /// Feeders need to expose their price panel capabilities at this public path
        access(all) view fun getPriceFeederStoragePath(): StoragePath { return PriceOracle._PriceFeederStoragePath! }
        access(all) view fun getPriceFeederPublicPath(): PublicPath { return PriceOracle._PriceFeederPublicPath! }
    }

    /// Each oracle contract will hold its own certificate to identify itself.
    ///
    /// Only the oracle contract can mint the certificate.
    ///
    /// TODO: to confirm if contract can be upgraded with change: `OracleInterface.IdentityCertificate -> OracleInterface.OracleCertificate`
    access(all) resource OracleCertificate: OracleInterface.OracleCertificate {}

    /// Reader certificate is used to provide proof of its address.In fact, anyone can mint their reader certificate.
    ///
    /// Readers only need to apply for a certificate to any oracle contract once.
    /// The contract will control the read permission of the readers according to the address whitelist.
    /// Please do not share your certificate capability with others and take the responsibility of community governance.
    ///
    access(all) resource ReaderCertificate: OracleInterface.IdentityCertificate {}


    /// Calculate the median of the price feed after filtering out expired data
    ///
    access(contract) view fun takeMedianPrice(): UFix64 {
        let certificateRef = self.account.storage.borrow<&OracleCertificate>(from: self._CertificateStoragePath)
                             ?? panic("Lost PriceOracle certificate resource.")

        var priceList: [UFix64] = []
        
        for oracleAddr in self._FeederWhiteList.keys {
            let pricePanelCap = getAccount(oracleAddr).capabilities.get<&{OracleInterface.PriceFeederPublic}>(PriceOracle._PriceFeederPublicPath!)
            // Get valid feeding-price
            if (pricePanelCap.check()) {
                let price = pricePanelCap.borrow()!.fetchPrice(certificate: certificateRef)
                if(price > 0.0) {
                    /// cannot use append() as this is inside view function
                    priceList = priceList.concat([price])
                }
            }
        }

        let len = priceList.length
        // If the number of valid prices is insufficient
        if (len < self._MinFeederNumber) {
            return 0.0
        }
        // sort
        let sortPriceList = OracleConfig.sortUFix64List(list: priceList)

        // find median
        var mid = 0.0
        if (len % 2 == 0) {
            let v1 = sortPriceList[len/2-1]
            let v2 = sortPriceList[len/2]
            mid = UFix64(v1+v2)/2.0
        } else {
            mid = sortPriceList[(len-1)/2]
        }
        return mid
    }

    access(contract) view fun getFeederWhiteListPrice(): [UFix64] {
        let certificateRef = self.account.storage.borrow<&OracleCertificate>(from: self._CertificateStoragePath)
            ?? panic("Lost PriceOracle certificate resource.")
        var priceList: [UFix64] = []

        for oracleAddr in PriceOracle._FeederWhiteList.keys {
            let pricePanelCap = getAccount(oracleAddr).capabilities.get<&{OracleInterface.PriceFeederPublic}>(PriceOracle._PriceFeederPublicPath!)
            if (pricePanelCap.check()) {
                let price = pricePanelCap.borrow()!.fetchPrice(certificate: certificateRef)
                if(price > 0.0) {
                    priceList = priceList.concat([price])
                } else {
                    priceList = priceList.concat([0.0])
                }
            } else {
                priceList = priceList.concat([0.0])
            }
        }
        return priceList
    }

    /// Calculate the *raw* median of the price feed with no filtering of expired data.
    ///
    access(contract) view fun getRawMedianPrice(): UFix64 {
        let certificateRef = self.account.storage.borrow<&OracleCertificate>(from: self._CertificateStoragePath) ?? panic("Lost PriceOracle certificate resource.")
        var priceList: [UFix64] = []
        for oracleAddr in PriceOracle._FeederWhiteList.keys {
            let pricePanelCap = getAccount(oracleAddr).capabilities.get<&{OracleInterface.PriceFeederPublic}>(PriceOracle._PriceFeederPublicPath!)
            if (pricePanelCap.check()) {
                let price = pricePanelCap.borrow()!.getRawPrice(certificate: certificateRef)
                priceList = priceList.concat([price])
            } else {
                priceList = priceList.concat([0.0])
            }
        }
        // sort
        let sortPriceList = OracleConfig.sortUFix64List(list: priceList)

        // find median
        let len = priceList.length
        var mid = 0.0
        if (len % 2 == 0) {
            let v1 = sortPriceList[len/2-1]
            let v2 = sortPriceList[len/2]
            mid = UFix64(v1+v2)/2.0
        } else {
            mid = sortPriceList[(len-1)/2]
        }
        return mid
    }

    /// Calculate the published block height of the *raw* median data. If it's an even list, it is the smaller one of the two middle value.
    ///
    access(contract) view fun getRawMedianBlockHeight(): UInt64 {
        let certificateRef = self.account.storage.borrow<&OracleCertificate>(from: self._CertificateStoragePath) ?? panic("Lost PriceOracle certificate resource.")
        var latestBlockHeightList: [UInt64] = []
        for oracleAddr in PriceOracle._FeederWhiteList.keys {
            let pricePanelCap = getAccount(oracleAddr).capabilities.get<&{OracleInterface.PriceFeederPublic}>(PriceOracle._PriceFeederPublicPath!)
            if (pricePanelCap.check()) {
                let latestPublishBlockHeight = pricePanelCap.borrow()!.getLatestPublishBlockHeight()
                latestBlockHeightList = latestBlockHeightList.concat([latestPublishBlockHeight])
            } else {
                latestBlockHeightList = latestBlockHeightList.concat([0])
            }
        }
        // sort
        let sortHeightList = OracleConfig.sortUInt64List(list: latestBlockHeightList)

        // find median
        let len = sortHeightList.length
        var midHeight: UInt64 = 0
        if (len % 2 == 0) {
            let h1 = sortHeightList[len/2-1]
            let h2 = sortHeightList[len/2]
            midHeight = (h1 < h2)? h1:h2
        } else {
            midHeight = sortHeightList[(len-1)/2]
        }
        return midHeight
    }

    access(contract) fun configOracle(
        priceIdentifier: String,
        minFeederNumber: Int,
        feederStoragePath: StoragePath,
        feederPublicPath: PublicPath,
        readerStoragePath: StoragePath
    ) {
        emit ConfigOracle(
            oldType: self._PriceIdentifier,
            newType: priceIdentifier,
            oldMinFeederNumber: self._MinFeederNumber,
            newMinFeederNumber: minFeederNumber
        )

        self._PriceIdentifier = priceIdentifier
        self._MinFeederNumber = minFeederNumber
        self._PriceFeederStoragePath = feederStoragePath
        self._PriceFeederPublicPath = feederPublicPath
        self._PriceReaderStoragePath = readerStoragePath
    }

    access(all) view fun getFeederWhiteList(): [Address] {
        return PriceOracle._FeederWhiteList.keys
    }

    access(all) view fun getReaderWhiteList(from: UInt64, to: UInt64): [Address] {
        let readerAddrs = PriceOracle._ReaderWhiteList.keys
        let readerLen = UInt64(readerAddrs.length)
        assert(from <= to && from < readerLen, message: "Index out of range")
        var _to = to
        if _to == 0 || _to == UInt64.max || _to >= readerLen {
            _to = readerLen-1
        }
        return readerAddrs.slice(from: Int(from), upTo: Int(_to+1))
    }

    /// Community administrator, Increment Labs will then collect community feedback and initiate voting for governance.
    ///
    access(all) resource Admin: OracleInterface.Admin {
        /// 
        access(all) fun configOracle(
            priceIdentifier: String,
            minFeederNumber: Int,
            feederStoragePath: StoragePath,
            feederPublicPath: PublicPath,
            readerStoragePath: StoragePath
        ) {
            PriceOracle.configOracle(
                priceIdentifier: priceIdentifier,
                minFeederNumber: minFeederNumber,
                feederStoragePath: feederStoragePath,
                feederPublicPath: feederPublicPath,
                readerStoragePath: readerStoragePath
            )
        }

        access(all) fun addFeederWhiteList(feederAddr: Address) {
            // Check if feeder prepared price panel first
            let PriceFeederCap = getAccount(feederAddr).capabilities.get<&{OracleInterface.PriceFeederPublic}>(PriceOracle._PriceFeederPublicPath!)
            assert(PriceFeederCap.check(), message: "Need to prepare data feeder resource capability first.")

            PriceOracle._FeederWhiteList[feederAddr] = true

            emit AddFeederWhiteList(addr: feederAddr)
        }

        access(all) fun addReaderWhiteList(readerAddr: Address) {
            PriceOracle._ReaderWhiteList[readerAddr] = true
            emit AddReaderWhiteList(addr: readerAddr)
        }

        access(all) fun delFeederWhiteList(feederAddr: Address) {
            PriceOracle._FeederWhiteList.remove(key: feederAddr)
            emit DelFeederWhiteList(addr: feederAddr)
        }

        access(all) fun delReaderWhiteList(readerAddr: Address) {
            PriceOracle._ReaderWhiteList.remove(key: readerAddr)
            emit DelReaderWhiteList(addr: readerAddr)
        }

        access(all) view fun getFeederWhiteListPrice(): [UFix64] {
            return PriceOracle.getFeederWhiteListPrice()
        }

        access(all) view fun getFeederWhiteList(): [Address] {
            return PriceOracle._FeederWhiteList.keys
        }

        access(all) view fun getReaderWhiteList(): [Address] {
            return PriceOracle._ReaderWhiteList.keys
        }
    }

    init() {
        self._FeederWhiteList = {}
        self._ReaderWhiteList = {}
        self._MinFeederNumber = 1
        self._PriceIdentifier = nil

        self._CertificateStoragePath = /storage/oracle_certificate
        self._OraclePublicStoragePath = /storage/oracle_public

        self._PriceFeederStoragePath = nil
        self._PriceFeederPublicPath = nil
        self._PriceReaderStoragePath = nil
        self._reservedFields = {}

        // Local admin resource
        destroy <- self.account.storage.load<@AnyResource>(from: OracleConfig.OracleAdminPath)
        self.account.storage.save(<-create Admin(), to: OracleConfig.OracleAdminPath)
        // Create oracle ceritifcate
        destroy <- self.account.storage.load<@AnyResource>(from: self._CertificateStoragePath)
        self.account.storage.save(<-create OracleCertificate(), to: self._CertificateStoragePath)
        // Public interface
        destroy <- self.account.storage.load<@AnyResource>(from: self._OraclePublicStoragePath)
        self.account.storage.save(<-create OraclePublic(), to: self._OraclePublicStoragePath)
        self.account.capabilities.publish(
            self.account.capabilities.storage.issue<&{OracleInterface.OraclePublicInterface_Reader}>(self._OraclePublicStoragePath),
            at: OracleConfig.OraclePublicInterface_ReaderPath
        )
        self.account.capabilities.publish(
            self.account.capabilities.storage.issue<&{OracleInterface.OraclePublicInterface_Feeder}>(self._OraclePublicStoragePath),
            at: OracleConfig.OraclePublicInterface_FeederPath
        )
    }
}