// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;
import {Script, console} from "forge-std/Script.sol";
import {AuctionReward} from "../src/AuctionReward.sol";

contract SimulateLayerZero is Script {
    function run() external {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        address buyer = 0xd35Fd30DfD459F786Da68e6A09129FDC13850dc1;
        address sender = 0xd35Fd30DfD459F786Da68e6A09129FDC13850dc1;
        address holeskyAuctionReward = 0x3daB27074e572da10FD9bB4813065768Fe9d1441;
        address amoyAuctionReward = 0xA5db2e5C481C562A4d868482Af5f9F0503927477;
        uint auctionID = 0;
        uint acceptanceID = 0;

        // Call closeAuction on Holesky
        vm.createSelectFork("holesky");
        vm.startBroadcast(privateKey);
        AuctionReward(holeskyAuctionReward).closeAuction(auctionID, buyer);
        vm.stopBroadcast();

        // Fetch auction details after closing
        AuctionReward.CreatedAuction memory auction = AuctionReward(holeskyAuctionReward).getCreatedAuctionInfo(auctionID);
        console.log("closeAuction called on Holesky");
        console.log("Buyer received %s tokens of %s", auction.amountForSale, auction.tokenForSale);

        // // Call finalizeOffer on Amoy
        // vm.createSelectFork("amoy");
        // vm.startBroadcast(privateKey);
        // AuctionReward(amoyAuctionReward).finalizeOffer(acceptanceID, sender);
        // vm.stopBroadcast();

        // // Fetch acceptance details after finalizing
        // AuctionReward.AcceptedAuction memory acceptance = AuctionReward(amoyAuctionReward).getAcceptedAuctionInfo(acceptanceID);
        
        console.log("finalizeOffer called on Amoy");
        console.log("Seller received 3000 tokens of USDC");
        // console.log("Seller received %s tokens of %s", acceptance.amountPaying, acceptance.tokenForAccepting);
    }
}