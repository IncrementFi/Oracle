import PublicPriceOracle from "../contracts/PublicPriceOracle.cdc"

access(all) fun main(): {Address: String} {
    return PublicPriceOracle.getAllSupportedOracles()
}