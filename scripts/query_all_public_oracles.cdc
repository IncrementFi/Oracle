import PublicPriceOracle from "../contracts/PublicPriceOracle.cdc"

pub fun main(): {Address: String} {
    return PublicPriceOracle.getAllSupportedOracles()
}