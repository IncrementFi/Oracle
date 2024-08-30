import PublicPriceOracle from "../contracts/PublicPriceOracle.cdc"

access(all) fun main(oracleAddr: Address): [AnyStruct] {
    return [
        PublicPriceOracle.getLatestPrice(oracleAddr: oracleAddr),
        PublicPriceOracle.getLatestBlockHeight(oracleAddr: oracleAddr)
    ]
}