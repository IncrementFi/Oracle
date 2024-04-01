import PublicPriceOracle from "../contracts/PublicPriceOracle.cdc"

pub fun main(oracleAddr: Address): [AnyStruct] {
    return [
        PublicPriceOracle.getLatestPrice(oracleAddr: oracleAddr),
        PublicPriceOracle.getLatestBlockHeight(oracleAddr: oracleAddr)
    ]
}