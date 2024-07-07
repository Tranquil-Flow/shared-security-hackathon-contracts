// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Script, console} from "forge-std/Script.sol";
import {AuctionReward} from "../src/AuctionReward.sol";

/* Chain IDs
    * 17000: Holesky testnet
    * 80002: Amoy testnet
*/

contract Deploy is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Deploy to Holesky testnet
        vm.chainId(17000);
        AuctionReward auctionRewardHolesky = new AuctionReward();
        console.log("AuctionReward deployed on Holesky at:", address(auctionRewardHolesky));

        // Deploy to Amoy testnet
        vm.chainId(80002);
        AuctionReward auctionRewardAmoy = new AuctionReward();
        console.log("AuctionReward deployed on Amoy at:", address(auctionRewardAmoy));

        vm.stopBroadcast();
    }
}