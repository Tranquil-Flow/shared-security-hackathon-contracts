// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

interface IERC20 {
    function transferFrom(address from, address to, uint256 amount) external;
    function balanceOf(address account) external view returns (uint256);
}

// TODO: Implement Fees for Auctions
// TODO: Implement Rewards for Attestors

/// @title AuctionReward
/// @author Tranquil-Flow
/// @notice A contract for P2P transferring of tokens across multiple chains using Dutch Auctions
/// @dev Verification of auctions is done by AVS attestors
contract AuctionReward {
    struct CreatedAuction {
        bool auctionOpen;            // True = Auction is open, False = Auction is closed
        address seller;              // Address of the auction creator
        address buyer;               // Address of the auction buyer
        address tokenForSale;        // Token being sold
        address tokenForPayment;     // Token accepted as payment
        uint amountForSale;          // Amount of tokenForSale being sold
        uint startingPrice;          // Amount of tokenForPayment for the amountForSale of tokenForSale at the start of the auction
        uint endPrice;               // Amount of tokenForPayment for the amountForSale of tokenForSale at the end of the auction
        uint startAt;                // Timestamp of when the auction started
        uint expiresAt;              // Timestamp of when the auction ends
        uint auctionChainID;         // Chain ID of where the auction is created
        uint acceptingOfferChainID;  // Chain ID of where the auction is accepted
    }
    
    uint public createdAuctionCounter;
    mapping(uint => CreatedAuction) public createdAuctions;

    struct AcceptedAuction {
        bool auctionAccepted;        // True = Auction offer is finalized, False = Auction offer is not finalized
        uint auctionId;              // Auction ID of the accepted auction
        uint createdAuctionChainId;  // Chain ID of where the created auction is
        address seller;              // Address of the auction seller
        address buyer;               // Address of the auction buyer
        address tokenForAccepting;   // Token being used as payment to accept auction
        uint amountPaying;           // Amount of tokenForAccepting being paid
        uint acceptOfferTimestamp;   // Timestamp of when the auction was accepted
    }

    uint public acceptanceCounter;
    mapping(uint => AcceptedAuction) public acceptedAuctions;

    mapping(uint => mapping(uint => bool)) public offerMade;

    event AuctionCreated(
        uint indexed auctionId,
        address seller,
        address tokenForSale,
        address tokenForPayment,
        uint amountForSale,
        uint startingPrice,
        uint endPrice,
        uint startAt,
        uint expiresAt,
        uint indexed auctionChainId,
        uint indexed acceptingOfferChainId
    );

    event AuctionAccepted(
        uint indexed acceptanceId,
        uint indexed auctionId,
        uint indexed createdAuctionChainId,
        address buyer,
        address tokenForAccepting,
        uint amountPaying,
        uint acceptOfferTimestamp
    );

    error InvalidPriceRange();
    error InsufficientTokensForSale();
    error InvalidAuctionID();
    error OfferAlreadyMade(uint auctionId, uint chainId);
    error NoOfferMade(uint auctionId, uint chainId);
    error OfferAlreadyFinalized(uint acceptanceId);

    constructor() {
    }

    /// @notice Sets up a Dutch auction
    function createAuction(
        address _tokenForSale,
        address _tokenForPayment,
        uint _startingPrice,
        uint _endPrice,
        uint _duration,
        uint _amountForSale,
        uint _auctionChainID,
        uint _acceptingOfferChainID
    ) external {
        if (_startingPrice < _endPrice) {
            revert InvalidPriceRange();
        }

        if (IERC20(_tokenForSale).balanceOf(msg.sender) < _amountForSale) {
            revert InsufficientTokensForSale();
        }

        IERC20(_tokenForSale).transferFrom(msg.sender, address(this), _amountForSale);
        uint timeNow = block.timestamp;
        uint createdAuctionID = createdAuctionCounter;

        createdAuctions[createdAuctionID] = CreatedAuction({
            auctionOpen: true,
            seller: msg.sender,
            buyer: address(0),
            tokenForSale: _tokenForSale,
            tokenForPayment: _tokenForPayment,
            amountForSale: _amountForSale,
            startingPrice: _startingPrice,
            endPrice: _endPrice,
            startAt: timeNow,
            expiresAt: timeNow + _duration,
            auctionChainID: _auctionChainID,
            acceptingOfferChainID: _acceptingOfferChainID
        });

        createdAuctionCounter++;

        emit AuctionCreated(
            createdAuctionID,
            msg.sender,
            _tokenForSale,
            _tokenForPayment,
            _amountForSale,
            _startingPrice,
            _endPrice,
            timeNow,
            timeNow + _duration,
            _auctionChainID,
            _acceptingOfferChainID
        );
    }

    /// @notice Accepts an auction that has been created on another chain
    function acceptAuction(uint _auctionId, uint _createdAuctionChainId, address _tokenForAccepting, uint _amountPaying) external {
        if (offerMade[_auctionId][_createdAuctionChainId]) {
            revert OfferAlreadyMade(_auctionId, _createdAuctionChainId);
        }
        IERC20(_tokenForAccepting).transferFrom(msg.sender, address(this), _amountPaying);
        uint timeNow = block.timestamp;
        uint acceptedOfferID = acceptanceCounter;

        acceptedAuctions[acceptedOfferID] = AcceptedAuction({
            auctionAccepted: false,
            auctionId: _auctionId,
            createdAuctionChainId: _createdAuctionChainId,
            seller: address(0),
            buyer: msg.sender,
            tokenForAccepting: _tokenForAccepting,
            amountPaying: _amountPaying,
            acceptOfferTimestamp: timeNow
        });
        
        acceptanceCounter++;
        offerMade[_auctionId][_createdAuctionChainId] = true;
        
        emit AuctionAccepted(
            acceptedOfferID,
            _auctionId,
            _createdAuctionChainId,
            msg.sender,
            _tokenForAccepting,
            _amountPaying,
            timeNow
        );

    }

    /// @notice Resumes an auction if the proposed offer was determined to not be valid by AVS attestors
    /// @param _auctionId The ID of the auction
    /// @param _createdAuctionChainId The chain ID of the created auction
    function resumeAuction(uint _auctionId, uint _createdAuctionChainId) external {
        if (!offerMade[_auctionId][_createdAuctionChainId]) {
            revert NoOfferMade(_auctionId, _createdAuctionChainId);
        }

        offerMade[_auctionId][_createdAuctionChainId] = false;
    }

    /// @notice Closes an auction once a valid offer has been made and AVS attestors have validated the transaction
    function closeAuction() external {
    }

    /// @notice Finalizes an auction offer once the AVS attestors have validated the auction
    function finalizeOffer() external {
    }

    /// @notice Claims rewards for AVS attestors
    function claimRewards() external {
    }

    /// @notice Withdraws tokens from an expired auction
    function withdrawExpiredAuction() external {
    }

    /// @notice Withdraws tokens from a failed offer acceptance
    function withdrawFailedOffer() external {
    }

    /// @notice Gets the current price of a created auction
    /// @param _auctionId The ID of the auction
    /// @return The current price of the auction in token amount of tokenForPayment
    function getPrice(uint _auctionId) public view returns (uint) {
        if (_auctionId >= createdAuctionCounter) {
            revert InvalidAuctionID();
        }

        CreatedAuction storage auction = createdAuctions[_auctionId];

        if (block.timestamp >= auction.expiresAt) {
            return auction.endPrice;
        }

        uint timeElapsed = block.timestamp - auction.startAt;
        uint priceDifference = auction.startingPrice - auction.endPrice;
        uint duration = auction.expiresAt - auction.startAt;
        uint discount = (priceDifference * timeElapsed) / duration;
        uint currentPrice = auction.startingPrice - discount;

        return currentPrice < auction.endPrice ? auction.endPrice : currentPrice;
    }

    /// @notice Gets the price of an auction at a specified timestamp
    /// @param _auctionId The ID of the auction
    /// @param _timestamp The timestamp to calculate the price at
    /// @return The price of the auction at the specified timestamp in token amount of tokenForPayment
    function getPriceAtTime(uint _auctionId, uint _timestamp) public view returns (uint) {
        if (_auctionId >= createdAuctionCounter) {
            revert InvalidAuctionID();
        }

        CreatedAuction storage auction = createdAuctions[_auctionId];

        if (_timestamp <= auction.startAt) {
            return auction.startingPrice;
        } else if (_timestamp >= auction.expiresAt) {
            return auction.endPrice;
        } else {
            uint timeElapsed = _timestamp - auction.startAt;
            uint priceDifference = auction.startingPrice - auction.endPrice;
            uint duration = auction.expiresAt - auction.startAt;
            uint discount = (priceDifference * timeElapsed) / duration;
            uint price = auction.startingPrice - discount;

            return price < auction.endPrice ? auction.endPrice : price;
        }
    }

    /// @notice Gets a created auctions information
    /// @param _auctionId The ID of the auction
    /// @return The auction information
    function getCreatedAuctionInfo(uint _auctionId) public view returns (CreatedAuction memory) {
        return createdAuctions[_auctionId];
    }

    /// @notice Gets an accepted auctions information
    /// @param _acceptanceId The ID of the acceptance
    /// @return The acceptance information
    function getAcceptedAuctionInfo(uint _acceptanceId) public view returns (AcceptedAuction memory) {
        return acceptedAuctions[_acceptanceId];
    }

}