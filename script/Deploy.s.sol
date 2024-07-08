// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Script, console} from "forge-std/Script.sol";
import {AuctionReward} from "../src/AuctionReward.sol";

// TODO: Update the endpoint address automatically for the chain you are deploying to

contract Deploy is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        uint256 chainId = block.chainid;

        vm.startBroadcast(deployerPrivateKey);

        // Use LayerZero endpoint address of chain you are deploying to
        // https://docs.layerzero.network/v2/developers/evm/technical-reference/deployed-contracts
        // Holesky: 0x6EDCE65403992e310A62460808c4b910D972f10f
        // Amoy: 0x6EDCE65403992e310A62460808c4b910D972f10f
        AuctionReward auctionReward = new AuctionReward(0x6EDCE65403992e310A62460808c4b910D972f10f);
        
        console.log("AuctionReward deployed on Chain ID %s at: %s", chainId, address(auctionReward));

        vm.stopBroadcast();
    }
}