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
contract AuctionReward {
    struct CreatedAuction {
        bool auctionOpen;            // True = Auction is open, False = Auction is closed
        address seller;              // Address of the auction creator
        address buyer;               // Address of the auction buyer
        address tokenForSale;         // Token being sold
        address tokenForPayment;      // Token accepted as payment
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
        uint auctionId;              // Auction ID of the accepted auction
        uint createdAuctionChainId;  // Chain ID of where the created auction is
        address seller;              // Address of the auction seller
        address buyer;               // Address of the auction buyer
        address tokenForAccepting;   // Token being used as payment to accept auction
        uint amountPaying;           // Amount of tokenForAccepting being paid
        uint acceptOffertimestamp;   // Timestamp of when the auction was accepted
    }

    uint public acceptanceCounter;
    mapping(uint => AuctionAcceptance) public auctionAcceptances;

    event AuctionCreated(
        uint indexed auctionId,
        address seller,
        address indexed tokenForSale,
        address indexed tokenForPayment,
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
        address indexed buyer,
        uint amountPaying,
        uint acceptOfferTimestamp
    );

    error InvalidPriceRange();
    error InsufficientTokensForSale();
    error InvalidAuctionID();

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
        if (_startingPrice <= _endPrice) {
            revert InvalidPriceRange();
        }

        if (IERC20(_tokenForSale).balanceOf(msg.sender) < _amountForSale) {
            revert InsufficientTokensForSale();
        }

        uint timeNow = block.timestamp;
        IERC20(_tokenForSale).transferFrom(msg.sender, address(this), _amountForSale);

        createdAuctions[createdAuctionCounter] = Auction({
            auctionOpen: true,
            seller: msg.sender,
            buyer: address(0),
            tokenForSale: IERC20(_tokenForSale),
            tokenForPayment: IERC20(_tokenForPayment),
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
            auctionId,
            msg.sender,
            _tokenForSale,
            _tokenForPayment,
            _amountForSale,
            _startingPrice,
            _endPrice,
            timeNow,
            timeNow + _duration,
            _auctionChainId,
            _acceptingOfferChainId
        );
    }

    /// @notice Accepts an auction
    function acceptAuction(uint _auctionId, uint _createdAuctionChainId, address _tokenForAccepting, uint _amountPaying) external {
        uint timeNow = block.timestamp;
        IERC20(_tokenForAccepting).transferFrom(msg.sender, address(this), _amountPaying);
        
        uint acceptanceId = acceptanceCounter;
        acceptedAuctions[acceptanceId] = AcceptedAuction({
            auctionId: _auctionId,
            createdAuctionChainId: _createdAuctionChainId,
            seller: address(0),
            buyer: msg.sender,
            tokenForAccepting: _tokenForAccepting,
            amountPaying: _amountPaying,
            timestamp: timeNow
        });
        
        acceptanceCounter++;
        
        emit AuctionAccepted(
            acceptanceId,
            _auctionId,
            _createdAuctionChainId,
            msg.sender,
            _tokenForAccepting
            _amountPaying,
            timeNow
        );

    }

    /// @notice Closes an auction once a valid offer has been made and AVS attestors have validated the transaction
    function closeAuction() external {
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

    /// @notice Gets an auctions information
    /// @param _auctionId The ID of the auction
    /// @return The auction information
    function getAuctionInfo(uint _auctionId) public view returns (CreatedAuction memory) {
        return createdAuctions[_auctionId];
    }

}