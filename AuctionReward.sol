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

    error InvalidPriceRange();
    error InsufficientTokensForSale();

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
            startAt: block.timestamp,
            expiresAt: block.timestamp + _duration,
            auctionChainID: _auctionChainID,
            acceptingOfferChainID: _acceptingOfferChainID
        });

        createdAuctionCounter++;
    }

    /// @notice Accepts an auction
    function acceptAuction(uint _auctionId, uint _createdAuctionChainId, address _tokenForAccepting, uint _amountPaying) external {
        
        IERC20(_tokenForAccepting).transferFrom(msg.sender, address(this), _amount);
        
        uint acceptanceId = acceptanceCounter;
        acceptedAuctions[acceptanceId] = AcceptedAuction({
            auctionId: _auctionId,
            createdAuctionChainId: _createdAuctionChainId,
            seller: address(0),
            buyer: msg.sender,
            tokenForAccepting: _tokenForAccepting,
            amountPaying: _amountPaying,
            timestamp: block.timestamp
        });
        
        acceptanceCounter++;
        
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
        CreatedAuction storage auction = createdAuctions[_auctionId];
        uint timeElapsed = block.timestamp - auction.startAt;
        uint priceDifference = auction.startingPrice - auction.endPrice;
        uint duration = auction.expiresAt - auction.startAt;
        uint discount = (priceDifference * timeElapsed) / duration;
        uint currentPrice = auction.startingPrice - discount;

        return currentPrice < auction.endPrice ? auction.endPrice : currentPrice;
    }

    /// @notice Gets an auctions information
    /// @param _auctionId The ID of the auction
    /// @return The auction information
    function getAuctionInfo(uint _auctionId) public view returns (CreatedAuction memory) {
        return createdAuctions[_auctionId];
    }

}