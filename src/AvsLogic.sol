// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { IAttestationCenter } from "./IAttestationCenter.sol";
import { OAppSender, MessagingFee } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/OAppSender.sol";
import { OAppCore } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/OAppCore.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

contract AvsLogic is OAppSender {

    event MessageSent(string message, uint32 dstEid);

    /// @notice Initializes the OApp with the source chain's endpoint address.
    /// @dev Preloaded with Endpoint Address for Holesky
    constructor() OAppCore(0x6EDCE65403992e310A62460808c4b910D972f10f, msg.sender) Ownable(msg.sender) {
        // Set connection to Holesky AuctionReward contract
        setPeer(
            40217,  // Holesky testnet
            0x0     // bytes32 of AuctionReward address on Holesky
        );
        
        // Set connection to Amoy AuctionReward contract
        setPeer(
            40267,  // Amoy testnet
            0x0     // bytes32 of AuctionReward address on Amoy
        );
    }

    /// @dev Unused function
    function beforeTaskSubmission(IAttestationCenter.TaskInfo calldata _taskInfo, bool _isApproved, bytes calldata _tpSignature, uint256[2] calldata _taSignature, uint256[] calldata _operatorIds) external {
    }

    /// @notice Called after AVS attestors confirm auction is valid
    function afterTaskSubmission(IAttestationCenter.TaskInfo calldata _taskInfo, bool _isApproved, bytes calldata _tpSignature, uint256[2] calldata _taSignature, uint256[] calldata _operatorIds) external {
        address sellerAddress = address(0xdead);
        address buyerAddress = address(0xdead);

        uint auctionID = 0;
        uint acceptanceID = 0;

        // Send message to Holesky to call closeAuction
        send(
            40217,                                          // Holesky testnet
            "closeAuction",                                 // Function to call
            0x0003010011010000000000000000000000000000c350, // 50000 Wei
            buyerAddress,                                   // The address of the buyer
            auctionID                                       // The auctionID
        );

        // Send message to Amoy to call finalizeOffer
    }


    /**
     * @notice Quotes the gas needed to pay for the full omnichain transaction in native gas or ZRO token.
     * @param _dstEid Destination chain's endpoint ID.
     * @param _message The message.
     * @param _options Message execution options (e.g., for sending gas to destination).
     * @param _payInLzToken Whether to return fee in ZRO token.
     */
    function quote(
        uint32 _dstEid,
        string memory _message,
        bytes memory _options,
        bool _payInLzToken
    ) public view returns (MessagingFee memory fee) {
        bytes memory payload = abi.encode(_message);
        fee = _quote(_dstEid, payload, _options, _payInLzToken);
    }

    /**
     * @notice Sends a message from the source to destination chain.
     * @param _dstEid Destination chain's endpoint ID.
     * @param _message The message to send.
     * @param _options Message execution options (e.g., for sending gas to destination).
     */
    function send(
        uint32 _dstEid,
        string memory _message,
        bytes calldata _options,
        address _sellerOrBuyer,
        uint _auctionOrAcceptqanceID
    ) public payable {
        // Encodes the message before invoking _lzSend.
        bytes memory _payload = abi.encode(_message, _sellerOrBuyer);
        _lzSend(
            _dstEid,
            _payload,
            _options,
            // Fee in native gas and ZRO token.
            MessagingFee(msg.value, 0),
            // Refund address in case of failed source message.
            payable(msg.sender) 
        );

        emit MessageSent(_message, _dstEid);
    }

    /// @notice Helper function to convert an address to bytes32
    function addressToBytes32(address _addr) public pure returns (bytes32) {
        return bytes32(uint256(uint160(_addr)));
    }
}