// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Script} from "forge-std/Script.sol";
import {AuctionReward} from "../src/AuctionReward.sol";

/* Chain IDs
    * 17000: Holesky testnet    (0xbCB715478a95E6157Ad395273477371424fF6b66)
    * 80002: Amoy testnet       (0xDBCEC270C887bbA9F15696054729872f479DE1a7)
*/

contract AcceptAuction is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        AuctionReward auctionReward = AuctionReward(0xDBCEC270C887bbA9F15696054729872f479DE1a7); // Replace with the deployed contract address

        uint256 auctionId = 0; // Replace with the auction ID
        uint256 createdAuctionChainId = 17000; // Replace with the created auction chainId
        address tokenForAccepting = 0x...; // Replace with the token address for accepting
        uint256 amountPaying = 2950;

        auctionReward.acceptAuction(auctionId, createdAuctionChainId, tokenForAccepting, amountPaying);

        vm.stopBroadcast();
    }
}