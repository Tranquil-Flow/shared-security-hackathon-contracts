// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Script, console2} from "forge-std/Script.sol";
import {AuctionReward} from "../src/AuctionReward.sol";
import {TestToken} from "../script/DeployTestTokens.s.sol"; // Make sure this import path is correct

contract CreateAuction is Script {
    function run() external {
        uint256 creatorPrivateKey = vm.envUint("CREATOR_PRIVATE_KEY");
        address creator = vm.addr(creatorPrivateKey);
        vm.startBroadcast(creatorPrivateKey);

        // Contract and token addresses
        AuctionReward auctionReward = AuctionReward(0xafaFB84a52898Efe2CC7412FCb8d999681C61bbc);
        address tokenForSale = 0x4cB2a1552a51557aB049A57f58a152fB832B159f;
        address tokenForPayment = 0x1FB7d6C5eb45468fB914737A20506F1aFB80bBd9;

        // Fetch token details
        TestToken tokenForSaleContract = TestToken(tokenForSale);
        TestToken tokenForPaymentContract = TestToken(tokenForPayment);
        string memory tokenSellTicker = tokenForSaleContract.symbol();
        string memory tokenBuyTicker = tokenForPaymentContract.symbol();
        uint8 tokenSellDecimals = tokenForSaleContract.decimals();
        uint8 tokenBuyDecimals = tokenForPaymentContract.decimals();

        // Auction parameters
        uint256 startingPrice = 3200 * 10**tokenBuyDecimals;
        uint256 endPrice = 3150 * 10**tokenBuyDecimals;
        uint256 duration = 3 days;
        uint256 amountForSale = 1 * 10**tokenSellDecimals; // 1 WETH
        uint256 auctionChainID = 17000; // Holesky testnet
        uint256 acceptingOfferChainID = 80002; // Amoy testnet

        // Mint tokens for the creator
        tokenForSaleContract.mint(creator, amountForSale);

        // Approve the AuctionReward contract to spend the tokens
        tokenForSaleContract.approve(address(auctionReward), amountForSale);

        // Create the auction
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

        console2.log("Created auction with tokenForSale: %s (%s)", tokenForSale, tokenSellTicker);
        console2.log("TokenForPayment: %s (%s)", tokenForPayment, tokenBuyTicker);
        console2.log("AmountForSale: %s %s", amountForSale / 10**tokenSellDecimals, tokenSellTicker);
        console2.log("StartingPrice: %s %s", startingPrice / 10**tokenBuyDecimals, tokenBuyTicker);
        console2.log("EndPrice: %s %s", endPrice / 10**tokenBuyDecimals, tokenBuyTicker);
        console2.log("Duration: %s seconds", duration);
    }
}