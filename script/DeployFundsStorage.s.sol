// SPDX-license-Identifier: MIT

pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {FundsStorage} from "../src/FundsStorage.sol";

contract DeployFundsStorage is Script {
    uint256 depositInterval = 30 days;
    uint256 withdrawInterval = 365 days;
    uint256 actionWindow = 48 hours;

    function run() external returns (FundsStorage) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        FundsStorage fundsStorage = new FundsStorage(depositInterval, withdrawInterval, actionWindow);

        vm.stopBroadcast();
        return (fundsStorage);
    }
}
