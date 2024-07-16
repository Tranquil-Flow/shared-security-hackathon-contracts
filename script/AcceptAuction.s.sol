// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Script, console2} from "forge-std/Script.sol";
import {AuctionReward} from "../src/AuctionReward.sol";
import {TestToken} from "../script/DeployTestTokens.s.sol";

contract AcceptAuction is Script {

    // Helper function to convert a decimal amount to the smallest unit
    function convertToSmallestUnit(uint256 wholeNumber, uint256 fractionalNumber, uint8 decimals) internal pure returns (uint256) {
        require(fractionalNumber < 10**decimals, "Fractional part must be less than 10^decimals");
        return (wholeNumber * 10**decimals) + (fractionalNumber * 10**(decimals - 1));
    }

    function run() external {
        uint256 acceptorPrivateKey = vm.envUint("ACCEPTOR_PRIVATE_KEY");
        address acceptor = vm.addr(acceptorPrivateKey);
        vm.startBroadcast(acceptorPrivateKey);

            // Old Testing: 0x21bef676c07648CE9FBCAF49C4a5fbE2882918fB
            // Transfer Demo: 0xD3fEEf9d124429654A837ec8a75f2ff55d71fE52
        AuctionReward auctionReward = AuctionReward(0x21bef676c07648CE9FBCAF49C4a5fbE2882918fB);
        uint256 auctionId = 15; // Replace with the actual auction ID
        uint256 createdAuctionChainId = 17000; // Holesky testnet
        address tokenForAccepting = 0x1FB7d6C5eb45468fB914737A20506F1aFB80bBd9;

        // Fetch token details
        TestToken tokenForAcceptingContract = TestToken(tokenForAccepting);
        string memory tokenTicker = tokenForAcceptingContract.symbol();
        uint8 tokenDecimals = tokenForAcceptingContract.decimals();

        // First number is the whole number, second number is the fractional part
        uint256 amountPaying = convertToSmallestUnit(3000, 0, tokenDecimals);

        // Mint tokens for the acceptor
        tokenForAcceptingContract.mint(acceptor, amountPaying);

        // Approve the AuctionReward contract to spend the tokens
        tokenForAcceptingContract.approve(address(auctionReward), amountPaying);

        // Get the current auction counter to determine the acceptance ID
        uint256 acceptanceId = auctionReward.acceptanceCounter();

        // Accept the auction
        auctionReward.acceptAuction(auctionId, createdAuctionChainId, tokenForAccepting, amountPaying);

        vm.stopBroadcast();

        console2.log("Accepted auction ID: %s", auctionId);
        console2.log("Acceptance ID: %s", acceptanceId);
        console2.log("TokenForAccepting: %s (%s)", tokenForAccepting, tokenTicker);
        console2.log("Amount paid: %d.%d %s", amountPaying / 10**tokenDecimals, (amountPaying % 10**tokenDecimals) / 10**(tokenDecimals - 1), tokenTicker);
        console2.log("Acceptor address: %s", acceptor);
        console2.log("Created auction chain ID: %s", createdAuctionChainId);
    }
}
