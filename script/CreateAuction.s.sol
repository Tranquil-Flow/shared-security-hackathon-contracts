// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Script, console2} from "forge-std/Script.sol";
import {AuctionReward} from "../src/AuctionReward.sol";
import {TestToken} from "../script/DeployTestTokens.s.sol"; // Ensure this import path is correct

contract CreateAuction is Script {

    // Helper function to convert a decimal amount to the smallest unit
    function convertToSmallestUnit(uint256 wholeNumber, uint256 fractionalNumber, uint8 decimals) internal pure returns (uint256) {
        require(fractionalNumber < 10**decimals, "Fractional part must be less than 10^decimals");
        return (wholeNumber * 10**decimals) + (fractionalNumber * 10**(decimals - 1));
    }

    function run() external {
        uint256 creatorPrivateKey = vm.envUint("CREATOR_PRIVATE_KEY");
        address creator = vm.addr(creatorPrivateKey);
        vm.startBroadcast(creatorPrivateKey);

        // Contract and token addresses
            // Old Testing: 0x1AeF71E391c67afda859adc3028F00D7612c55A8
            // LZ Testing: 0x7e6bec26f4E3923Af7D5Af09eb7E8FeE78A0F221
        AuctionReward auctionReward = AuctionReward(0x1AeF71E391c67afda859adc3028F00D7612c55A8);
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
        // First number is the whole number, second number is the fractional part
        uint256 startingPrice = convertToSmallestUnit(3000, 0, tokenBuyDecimals);
        uint256 endPrice = convertToSmallestUnit(2950, 0, tokenBuyDecimals);
        uint256 duration = 3 days;
        uint256 amountForSale = 1 * 10**tokenSellDecimals;
        uint256 auctionChainID = 17000; // Holesky testnet
        uint256 acceptingOfferChainID = 80002; // Amoy testnet

        // Mint tokens for the creator
        tokenForSaleContract.mint(creator, amountForSale);

        // Approve the AuctionReward contract to spend the tokens
        tokenForSaleContract.approve(address(auctionReward), amountForSale);

        // Get the current auction counter to determine the auction ID
        uint256 auctionId = auctionReward.createdAuctionCounter();

        // Get current block timestamp
        uint256 startAt = block.timestamp;
        uint256 expiresAt = startAt + duration;

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

        // Raw Logs, for debugging:
            // console2.log("Token for Sale: %s", tokenForSale);
            // console2.log("Token for Payment: %s", tokenForPayment);
            // console2.log("Starting Price: %s", startingPrice);
            // console2.log("End Price: %s", endPrice);
            // console2.log("Duration: %s", duration);
            // console2.log("Amount for Sale: %s", amountForSale);
            // console2.log("Auction Chain ID: %s", auctionChainID);
            // console2.log("Accepting Offer Chain ID: %s", acceptingOfferChainID);

        console2.log("Created auction with ID: %s", auctionId);
        console2.log("TokenForSale: %s (%s)", tokenForSale, tokenSellTicker);
        console2.log("TokenForPayment: %s (%s)", tokenForPayment, tokenBuyTicker);
        console2.log("AmountForSale: %s %s", amountForSale / 10**tokenSellDecimals, tokenSellTicker);
        console2.log("StartingPrice: %d.%d %s", startingPrice / 10**tokenBuyDecimals, (startingPrice % 10**tokenBuyDecimals) / 10**(tokenBuyDecimals - 1), tokenBuyTicker);
        console2.log("EndPrice: %d.%d %s", endPrice / 10**tokenBuyDecimals, (endPrice % 10**tokenBuyDecimals) / 10**(tokenBuyDecimals - 1), tokenBuyTicker);
        console2.log("Duration: %s seconds", duration);
        console2.log("Auction starts at (UNIX): %s", startAt);
        console2.log("Auction ends at (UNIX): %s", expiresAt);
    }
}
