// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { IAttestationCenter } from "./IAttestationCenter.sol";

import { OAppCore } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/OAppCore.sol";
import { OAppSender, MessagingFee } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/OAppSender.sol";
import { OptionsBuilder } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/libs/OptionsBuilder.sol";

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

contract AvsLogic is OAppSender {
    using OptionsBuilder for bytes;

    event MessageSent(uint _functionType, uint32 dstEid, address sellerOrBuyer, uint auctionOrAcceptanceID);

    /// @notice Initializes the OApp with the source chain's endpoint address.
    /// @dev Preloaded with Endpoint Address for Holesky
    constructor() OAppCore(0x6EDCE65403992e310A62460808c4b910D972f10f, msg.sender) Ownable(msg.sender) {
    }

    /// @dev Unused function
    function beforeTaskSubmission(IAttestationCenter.TaskInfo calldata _taskInfo, bool _isApproved, bytes calldata _tpSignature, uint256[2] calldata _taSignature, uint256[] calldata _operatorIds) external {
    }

    /// @notice Called after AVS attestors confirm auction is valid
    function afterTaskSubmission(IAttestationCenter.TaskInfo calldata _taskInfo, bool _isApproved, bytes calldata _tpSignature, uint256[2] calldata _taSignature, uint256[] calldata _operatorIds) external {
        // address sellerAddress = address(0xd35Fd30DfD459F786Da68e6A09129FDC13850dc1);
        // address buyerAddress = address(0xd35Fd30DfD459F786Da68e6A09129FDC13850dc1);

        // uint auctionID = 0;
        // uint acceptanceID = 0;

        // Calculate the amount of gas to have on contract
        // MessagingFee memory holeskyGas = quote(
        //     40217,                                      //_dstEid
        //     abi.encode(1, buyerAddress, auctionID),     // _message
        //     OptionsBuilder.
        //     newOptions()
        //     .addExecutorLzReceiveOption({ _gas: uint128(3000000), _value: uint128(0)}),                                // _options
        //     false                                       // _payInLzToken
        // );

        /* _taskInfo.data JSON:
        const data = {
            auctionId: Number(auctionId),
            acceptanceId: Number(acceptanceId),
            txAccepted: txAccepted,
            auctionChainId: Number(createdAuctionInfo.auctionChainID),
            acceptingOfferChainID: Number(createdAuctionInfo.acceptingOfferChainID),
            auctionCreationEOA: buyer,
            acceptingOfferEOA: createdAuctionInfo.seller
        };
        */

        // Get sellerAddress, buyerAddress, auctionID, acceptanceID from _taskInfo
        (uint auctionID,
        uint acceptanceID,
        ,
        ,
        ,
        address sellerAddress,
        address buyerAddress
        ) = abi.decode(_taskInfo.data, (uint, uint, bool, uint, uint, address, address));

        // Send message to Holesky to call closeAuction
        send(
            40217,
            1,
            OptionsBuilder.
            newOptions()
            .addExecutorLzReceiveOption({ _gas: uint128(3000000), _value: uint128(0)}),
            buyerAddress,
            auctionID
        );

        // Send message to Amoy to call finalizeOffer
        // send(
        //     40267,
        //     2,
        //     OptionsBuilder.
        //     newOptions()
        //     .addExecutorLzReceiveOption({ _gas: uint128(3000000), _value: uint128(0)}),
        //     sellerAddress,
        //     acceptanceID
        // );
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
     * @param _functionType 1 = closeAuction, 2 = finalizeOffer, 3 = resumeAuction
     * @param _options Message execution options (e.g., for sending gas to destination).
     */
    function send(
        uint32 _dstEid,
        uint _functionType,
        bytes memory _options,
        address _sellerOrBuyer,
        uint _auctionOrAcceptanceID
    ) public payable {
        // Encodes the message before invoking _lzSend.
        bytes memory _payload = abi.encode(_functionType, _sellerOrBuyer, _auctionOrAcceptanceID);
        _lzSend(
            _dstEid,
            _payload,
            _options,
            // Fee in native gas and ZRO token.
            MessagingFee(msg.value, 0),
            // Refund address in case of failed source message.
            payable(msg.sender) 
        );

        emit MessageSent(_functionType, _dstEid, _sellerOrBuyer, _auctionOrAcceptanceID);
    }

    /// @notice Helper function to convert an address to bytes32
    function addressToBytes32(address _addr) public pure returns (bytes32) {
        return bytes32(uint256(uint160(_addr)));
    }
}