import OracleInterface from "../../contracts/OracleInterface.cdc"
import OracleConfig from "../../contracts/OracleConfig.cdc"

// deploy code copied by a deployed contract
transaction(codeAddr: Address, codeName: String) {
    prepare(deployAccount: AuthAccount) {
        log("Transaction Start --------------- deploy code ".concat(codeName))

        let code = getAccount(codeAddr).contracts.get(name: codeName)!.code
        deployAccount.contracts.add(name: codeName, code: code)
        
        log("End -----------------------------")
    }
}