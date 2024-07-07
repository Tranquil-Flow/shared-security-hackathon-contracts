// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Script, console} from "forge-std/Script.sol";
import {AuctionReward} from "../src/AuctionReward.sol";

contract Deploy is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        uint256 chainId = block.chainid;

        vm.startBroadcast(deployerPrivateKey);

        AuctionReward auctionReward = new AuctionReward();
        
        console.log("AuctionReward deployed on Chain ID %s at: %s", chainId, address(auctionReward));

        vm.stopBroadcast();
    }
}