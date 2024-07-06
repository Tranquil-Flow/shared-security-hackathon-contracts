// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

interface IERC20 {
    function transferFrom(address from, address to, uint256 amount) external;
    function transfer(address to, uint256 amount) external;
    function balanceOf(address account) external view returns (uint256);
}

// TODO: Implement Basic auctioning flow
// TODO: Implement LayerZero for cross chain messaging
// TODO: Implement Rewards for Attestors

/// @title AuctionReward
/// @author Tranquil-Flow
/// @notice A contract for P2P transferring of tokens across multiple chains using Dutch Auctions
contract AuctionReward {
    uint256 private constant DURATION = 7 days;
    IERC20 public immutable tokenForSale;
    IERC20 public immutable tokenForPayment;
    uint256 public immutable amountForSale;
    address payable public immutable seller;
    uint256 public immutable startingPrice;
    uint256 public immutable startAt;
    uint256 public immutable expiresAt;
    uint256 public immutable discountRate;

    constructor() {

    }

    /// @notice Sets up a Dutch auction
    function createAuction() external {

    }

    /// @notice Accepts an auction
    function acceptAuction() external {

    }

    /// @notice Closes an auction once a valid offer has been made and AVS attestors have validated the transaction
    function closeAuction() external {
        
    }

    /// @notice Claims rewards for AVS attestors
    function claimRewards() external {

    }

    constructor(
        uint256 _startingPrice,
        uint256 _discountRate,
        address _tokenForSale,
        address _tokenForPayment,
        uint256 _amountForSale
    ) {
        seller = payable(msg.sender);
        startingPrice = _startingPrice;
        startAt = block.timestamp;
        expiresAt = block.timestamp + DURATION;
        discountRate = _discountRate;
        require(
            _startingPrice >= _discountRate * DURATION,
            "starting price < min"
        );
        tokenForSale = IERC20(_tokenForSale);
        tokenForPayment = IERC20(_tokenForPayment);
        amountForSale = _amountForSale;

        require(
            tokenForSale.balanceOf(address(this)) >= amountForSale,
            "insufficient tokens for sale"
        );
    }

    function getPrice() public view returns (uint256) {
        uint256 timeElapsed = block.timestamp - startAt;
        uint256 discount = discountRate * timeElapsed;
        return startingPrice - discount;
    }

    function buy(uint256 amount) external {
        require(block.timestamp < expiresAt, "auction expired");
        uint256 price = getPrice();
        uint256 totalCost = price * amount;
        require(amount <= amountForSale, "amount > tokens for sale");

        tokenForPayment.transferFrom(msg.sender, address(this), totalCost);
        tokenForSale.transfer(msg.sender, amount);

        if (tokenForSale.balanceOf(address(this)) == 0) {
            selfdestruct(seller);
        }
    }
}