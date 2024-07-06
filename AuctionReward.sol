// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

interface IERC20 {
    function transferFrom(address from, address to, uint256 amount) external;
    function transfer(address to, uint256 amount) external;
    function balanceOf(address account) external view returns (uint256);
}

// TODO: Implement Basic auctioning flow
// TODO: Implement LayerZero for cross chain messaging
// TODO: Implement Fees for Auctions
// TODO: Implement Rewards for Attestors

/// @title AuctionReward
/// @author Tranquil-Flow
/// @notice A contract for P2P transferring of tokens across multiple chains using Dutch Auctions
contract AuctionReward {
    struct Auction {
        bool auctionOpen;
        address seller;
        IERC20 tokenForSale;
        IERC20 tokenForPayment;
        uint amountForSale;
        uint startingPrice;
        uint endPrice;
        uint startAt;
        uint expiresAt;
        uint acceptingChainID;
    }

    uint public auctionCounter;
    mapping(uint => Auction) public auctions;

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
        uint _acceptingChainID
    ) external {
        if (_startingPrice <= _endPrice) {
            revert InvalidPriceRange();
        }

        if (IERC20(_tokenForSale).balanceOf(msg.sender) < _amountForSale) {
            revert InsufficientTokensForSale();
        }

        auctions[auctionCounter] = Auction({
            auctionOpen: true,
            seller: msg.sender,
            tokenForSale: IERC20(_tokenForSale),
            tokenForPayment: IERC20(_tokenForPayment),
            amountForSale: _amountForSale,
            startingPrice: _startingPrice,
            endPrice: _endPrice,
            startAt: block.timestamp,
            expiresAt: block.timestamp + _duration,
            acceptingChainID: _acceptingChainID
        });

        IERC20(_tokenForSale).transferFrom(msg.sender, address(this), _amountForSale);

        auctionCounter++;
    }

    /// @notice Accepts an auction
    function acceptAuction(uint _auctionId, uint _amount) external {
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

    /// @notice Gets the current price of the auction
    /// @param _auctionId The ID of the auction
    /// @return The current price of the auction in token amount of tokenForPayment
    function getPrice(uint _auctionId) public view returns (uint) {
        Auction storage auction = auctions[_auctionId];
        uint timeElapsed = block.timestamp - auction.startAt;
        uint priceDifference = auction.startingPrice - auction.endPrice;
        uint duration = auction.expiresAt - auction.startAt;
        uint discount = (priceDifference * timeElapsed) / duration;
        uint currentPrice = auction.startingPrice - discount;

        return currentPrice < auction.endPrice ? auction.endPrice : currentPrice;
    }

    /// @notice Gets the auction information
    /// @param _auctionId The ID of the auction
    /// @return The auction information
    function getAuctionInfo(uint _auctionId) public view returns (Auction memory) {
        return auctions[_auctionId];
    }

}