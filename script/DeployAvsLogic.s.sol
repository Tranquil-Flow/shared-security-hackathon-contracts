// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Script, console} from "forge-std/Script.sol";
import {AvsLogic} from "../src/AvsLogic.sol";

contract DeployAvsLogic is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        uint256 chainId = block.chainid;

        vm.startBroadcast(deployerPrivateKey);

        AvsLogic avsLogic = new AvsLogic();

        console.log("AvsLogic deployed on Chain ID %s at: %s", chainId, address(avsLogic));

        // Set the peer connections
        avsLogic.setPeer(
            40217, // Holesky testnet
            bytes32(uint256(uint160(0x7e6bec26f4E3923Af7D5Af09eb7E8FeE78A0F221))) // bytes32 of AuctionReward address on Holesky
        );

        avsLogic.setPeer(
            40267, // Amoy testnet
            bytes32(uint256(uint160(0x21bef676c07648CE9FBCAF49C4a5fbE2882918fB))) // bytes32 of AuctionReward address on Amoy
        );

        console.log("Peer connections set for AvsLogic");

        vm.stopBroadcast();
    }
}