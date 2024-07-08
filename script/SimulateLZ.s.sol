// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Script, console} from "forge-std/Script.sol";
import {AuctionReward} from "../src/AuctionReward.sol";

contract SimulateLayerZero is Script {
    function run() external {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");

        // Replace with the actual deployed AuctionReward contract addresses on Holesky and Amoy
        address buyer = 0x111111111117dc0aa78b770fa6a738034120c302;
        address sender = 0x111111111117dc0aa78b770fa6a738034120c302;
        address holeskyAuctionReward = 0x1AeF71E391c67afda859adc3028F00D7612c55A8;
        address amoyAuctionReward = 0x21bef676c07648CE9FBCAF49C4a5fbE2882918fB;

        // Define the auctionID and acceptanceID
        uint auctionID = 1;
        uint acceptanceID = 1;

        // Call closeAuction on Holesky
        vm.startBroadcast(privateKey);
        AuctionReward(holeskyAuctionReward).closeAuction(auctionID, buyer);
        vm.stopBroadcast();

        console.log("closeAuction called on Holesky");

        // Call finalizeOffer on Amoy
        vm.startBroadcast(privateKey);
        AuctionReward(amoyAuctionReward).finalizeOffer(acceptanceID, sender);
        vm.stopBroadcast();

        console.log("finalizeOffer called on Amoy");
    }
}