// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Script, console2} from "forge-std/Script.sol";
import {AuctionReward} from "../src/AuctionReward.sol";
import {TestToken} from "../script/DeployTestTokens.s.sol"; // Make sure this import path is correct

contract AcceptAuction is Script {
    function run() external {
        uint256 acceptorPrivateKey = vm.envUint("ACCEPTOR_PRIVATE_KEY");
        address acceptor = vm.addr(acceptorPrivateKey);
        vm.startBroadcast(acceptorPrivateKey);

        AuctionReward auctionReward = AuctionReward(0xafaFB84a52898Efe2CC7412FCb8d999681C61bbc);
        uint256 auctionId = 0; // Replace with the actual auction ID
        uint256 createdAuctionChainId = 17000; // Holesky testnet
        address tokenForAccepting = 0x1FB7d6C5eb45468fB914737A20506F1aFB80bBd9; // USDC token

        // Fetch token details
        TestToken tokenForAcceptingContract = TestToken(tokenForAccepting);
        string memory tokenTicker = tokenForAcceptingContract.symbol();
        uint8 tokenDecimals = tokenForAcceptingContract.decimals();

        uint256 amountPaying = 2900 * 10**tokenDecimals; //

        // Mint tokens for the acceptor
        tokenForAcceptingContract.mint(acceptor, amountPaying);

        // Approve the AuctionReward contract to spend the tokens
        tokenForAcceptingContract.approve(address(auctionReward), amountPaying);

        // Accept the auction
        auctionReward.acceptAuction(auctionId, createdAuctionChainId, tokenForAccepting, amountPaying);

        vm.stopBroadcast();

        console2.log("Accepted auction ID: %s", auctionId);
        console2.log("TokenForAccepting: %s (%s)", tokenForAccepting, tokenTicker);
        console2.log("Amount paid: %s %s", amountPaying / 10**tokenDecimals, tokenTicker);
        console2.log("Acceptor address: %s", acceptor);
        console2.log("Created auction chain ID: %s", createdAuctionChainId);
    }
}