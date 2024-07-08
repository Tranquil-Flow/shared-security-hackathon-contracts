// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Script, console} from "forge-std/Script.sol";
import {AvsLogic} from "../src/AvsLogic.sol";
import {IAttestationCenter} from "../src/IAttestationCenter.sol";

contract AvsLogicInteraction is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployerAddress = vm.addr(deployerPrivateKey);

        // Replace with the actual deployed AvsLogic contract address
        AvsLogic avsLogic = AvsLogic(0x2bF3A7B7fBB9Fd2BF89aDe70d0dbD408D185F6dE);

        // Dummy values for testing
        address sellerAddress = 0xd35Fd30DfD459F786Da68e6A09129FDC13850dc1;
        address buyerAddress = 0xd35Fd30DfD459F786Da68e6A09129FDC13850dc1;
        uint auctionID = 1;
        uint acceptanceID = 2;

        console.log("Seller Address:", sellerAddress);
        console.log("Buyer Address:", buyerAddress);
        console.log("Auction ID:", auctionID);
        console.log("Acceptance ID:", acceptanceID);

        // Prepare the TaskInfo struct with dummy data
        IAttestationCenter.TaskInfo memory taskInfo = IAttestationCenter.TaskInfo({
            proofOfTask: "dummy_proof",
            data: abi.encode(auctionID, acceptanceID, true, 40217, 40267, buyerAddress, sellerAddress),
            taskPerformer: deployerAddress,
            taskDefinitionId: 1
        });

        // Start the broadcast
        vm.startBroadcast(deployerPrivateKey);

        // Invoke the afterTaskSubmission function with dummy values
        // avsLogic.afterTaskSubmission(
        //     taskInfo,
        //     true,
        //     "dummy_tp_signature",
        //     [uint256(0), 0],
        //     new uint256[](0)
        // );

        // Invoke the testFunction
        avsLogic.testFunction(0);   // AuctionID

        // Stop the broadcast
        vm.stopBroadcast();

        console.log("afterTaskSubmission invoked successfully");
    }
}