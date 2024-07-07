// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Script} from "forge-std/Script.sol";
import {AuctionReward} from "../src/AuctionReward.sol";

/* Chain IDs
    * 17000: Holesky testnet    (0xbCB715478a95E6157Ad395273477371424fF6b66)
    * 80002: Amoy testnet       (0xDBCEC270C887bbA9F15696054729872f479DE1a7)
*/

contract CreateAuction is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        AuctionReward auctionReward = AuctionReward(0xbCB715478a95E6157Ad395273477371424fF6b66); // Replace with the deployed contract address

        address tokenForSale = 0x...; // Replace with the token address for sale
        address tokenForPayment = 0x...; // Replace with the token address for payment
        uint256 startingPrice = 3000;
        uint256 endPrice = 2900;
        uint256 duration = 3 days;
        uint256 amountForSale = 1;
        uint256 auctionChainID = 17000; // Replace with the auction chainId
        uint256 acceptingOfferChainID = 80002; // Replace with the accepting offer chainId

        auctionReward.createAuction(
            tokenForSale,
            tokenForPayment,
            startingPrice,
            endPrice,
            duration,
            amountForSale,
            auctionChainID,
            acceptingOfferChainID
        );

        vm.stopBroadcast();
    }
}